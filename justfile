set dotenv-load
set export
set shell := ["bash", "-lc"]

# List all recipes
default:
  @just --list

# --- LOCAL (no AWS required) ---

# Deploy databases to local k3d cluster
[group('local')]
deploy-local: _k3d
  kubectl apply -k kustomize/overlays/local --server-side

# DuckLake demo (Postgres + DuckDB + S3)
[group('local')]
ducklake-test: _deploy-ducklake
  uv run ducklake_test.py

# rclone CSI demo (S3 mount + filebrowser)
[group('local')]
rclone-test: _rclone-lab
  kubectl wait --for=condition=Ready pod -l app=filebrowser --timeout=120s
  kubectl exec deploy/filebrowser -- ls -la /srv
  @echo "rclone CSI working ✓"

# Validate all local examples
[group('local')]
validate-local: lint _validate-ddev _validate-k3d
  @echo "Local validation passed ✓"

# --- EKS (requires AWS) ---

# Create EKS cluster via Terraform
[group('eks')]
[working-directory: 'eksauto/terraform']
setup-eks: _awslogin _terraform-init
  terraform apply -auto-approve || { terraform destroy -auto-approve; terraform apply -auto-approve; }
  aws eks update-kubeconfig --name $(terraform output -raw cluster_name)
  kubectl get nodes || echo "Nodes starting (EKS Auto Mode)"

# Destroy EKS cluster
[group('eks')]
[working-directory: 'eksauto/terraform']
destroy-eks: _awslogin
  terraform destroy -auto-approve

# Deploy core manifests to EKS
[group('eks')]
deploy CLUSTER="training01": _awslogin (_eks-kubeconfig CLUSTER)
  kubectl apply -k kustomize/overlays/{{CLUSTER}}

# S3 Pod Identity demo (MySQL → S3 → rclone → restore)
[group('eks')]
s3-test: _awslogin _eks-kubeconfig _s3-clean _s3-infra _s3-deploy _s3-backup _s3-copy
  @echo "S3 Pod Identity test complete ✓"
  @echo "Run 'just s3-restore' to test restore, 'just s3-cleanup' when done"

# Restore MySQL backup from S3
[group('eks')]
s3-restore: _eks-kubeconfig
  -kubectl delete job restore-from-s3 -n s3-test
  kubectl apply -f kustomize-s3-pod-identity/jobs/restore.yaml
  kubectl wait --for=condition=Complete job/restore-from-s3 -n s3-test --timeout=300s
  kubectl logs job/restore-from-s3 -n s3-test -c mysqlsh-restore | tail -10

# Cleanup S3 Pod Identity resources
[group('eks')]
s3-cleanup:
  -kubectl delete -k kustomize-s3-pod-identity/jobs
  -kubectl delete -k kustomize-s3-pod-identity
  -helm uninstall csi-rclone -n veloxpack

# --- ARGOCD ---

# Create ArgoCD EKS capability
[group('argocd')]
argocd-create CLUSTER="training01": _awslogin
  #!/usr/bin/env bash
  set -euo pipefail
  IDC=$(just _idc-arn)
  [ "$IDC" = "null" ] && { echo "ERROR: Identity Center not configured"; exit 1; }
  aws eks create-capability --region $AWS_REGION --cluster-name {{CLUSTER}} --capability-name argocd --type ARGOCD \
    --role-arn "arn:aws:iam::$(just _account):role/eks-argocd-capability" --delete-propagation-policy RETAIN \
    --configuration '{"argoCd":{"awsIdc":{"idcInstanceArn":"'"$IDC"'","idcRegion":"'"$AWS_REGION"'"}}}'
  for i in {1..30}; do
    STATUS=$(aws eks describe-capability --cluster-name {{CLUSTER}} --capability-name argocd | jq -r '.capability.status')
    echo "Status: $STATUS"; [ "$STATUS" = "ACTIVE" ] && exit 0; sleep 10
  done

# Delete ArgoCD capability
[group('argocd')]
argocd-delete CLUSTER="training01": _awslogin
  -aws eks delete-capability --cluster-name {{CLUSTER}} --capability-name argocd --delete-propagation-policy DELETE --region $AWS_REGION

# Deploy ArgoCD ApplicationSet
[group('argocd')]
argocd-deploy CLUSTER="training01": _awslogin (_eks-kubeconfig CLUSTER)
  kubectl apply -k kustomize-argocd
  @echo "ApplicationSet deployed ✓"

# Get ArgoCD UI URL (auto-adds current user as admin)
[group('argocd')]
argocd-ui CLUSTER="training01": _awslogin
  #!/usr/bin/env bash
  set -euo pipefail
  USERNAME=$(just _username)
  USER_ID=$(aws identitystore get-user-id --identity-store-id "$(just _idc-store)" \
    --alternate-identifier '{"UniqueAttribute":{"AttributePath":"userName","AttributeValue":"'"$USERNAME"'"}}' | jq -r '.UserId // empty')
  if [ -n "$USER_ID" ]; then
    CURRENT=$(aws eks describe-capability --cluster-name {{CLUSTER}} --capability-name argocd | jq -r '.capability.configuration.argoCd // {}')
    if ! echo "$CURRENT" | jq -e --arg id "$USER_ID" '.rbacRoleMappings[]?.identities[]?.id == $id' >/dev/null 2>&1; then
      echo "Adding $USERNAME as admin..."
      aws eks update-capability --cluster-name {{CLUSTER}} --capability-name argocd \
        --configuration '{"argoCd":{"rbacRoleMappings":{"addOrUpdateRoleMappings":[{"role":"ADMIN","identities":[{"id":"'"$USER_ID"'","type":"SSO_USER"}]}]}}}' >/dev/null
      sleep 3
    fi
  fi
  aws eks describe-capability --cluster-name {{CLUSTER}} --capability-name argocd | jq -r '.capability.configuration.argoCd.serverUrl'

# Cleanup ArgoCD ApplicationSet
[group('argocd')]
argocd-cleanup:
  -kubectl delete -k kustomize-argocd

# --- EXTERNAL SECRETS ---

# Deploy External Secrets Operator
[group('secrets')]
secrets-deploy: _awslogin _eks-kubeconfig
  helm upgrade --install external-secrets oci://ghcr.io/external-secrets/charts/external-secrets \
    --namespace external-secrets --create-namespace --set installCRDs=true
  kubectl wait --for=condition=Available deploy/external-secrets -n external-secrets --timeout=180s
  kubectl rollout restart deploy -n external-secrets
  kubectl rollout status deploy/external-secrets -n external-secrets --timeout=60s
  kubectl apply -k kustomize-external-secrets
  @echo "External Secrets deployed ✓"

# Test External Secrets sync
[group('secrets')]
secrets-test:
  kubectl get externalsecret -n secrets-demo
  @kubectl get secret db-creds -n secrets-demo -o jsonpath='{.data.username}' | base64 -d && echo

# Cleanup External Secrets
[group('secrets')]
secrets-cleanup:
  -kubectl delete -k kustomize-external-secrets
  -helm uninstall external-secrets -n external-secrets
  -kubectl delete namespace external-secrets secrets-demo

# --- DRUPAL ---

# Setup Drupal CMS with FrankenPHP
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-setup:
  ddev add-on get ddev/ddev-frankenphp
  ddev dotenv set .ddev/.env.web --frankenphp-custom-extensions="apcu opcache intl bcmath"
  ddev start
  ddev restart
  ddev composer update --with-all-dependencies
  ddev composer require drupal/drupal_cms_starter drupal/drupal_cms_search drupal/drupal_cms_news
  ddev drush site:install --account-name=admin --account-pass=admin -y
  ddev drush recipe ../recipes/drupal_cms_starter
  ddev drush recipe ../recipes/drupal_cms_search
  ddev drush recipe ../recipes/drupal_cms_news

# Start Drupal
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-start:
  ddev start

# Stop Drupal
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-stop:
  ddev stop

# Get Drupal login link
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-login:
  ddev drush user:login

# Generate 100k test articles
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-generate:
  ddev drush php:script scripts/generate_news_content.php

# Run search performance tests
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-test:
  ddev drush search-api:rebuild-tracker content
  ddev drush search-api:index --batch-size=1000
  ddev drush php:script scripts/search_performance_test.php

# Load test Drupal (requires running DDEV)
[group('drupal')]
drupal-loadtest RATE="100" DURATION="30s":
  @echo "Load testing at {{RATE}} req/s for {{DURATION}}..."
  echo "GET http://drupal-cms-perftest.ddev.site/" | vegeta attack -duration={{DURATION}} -rate={{RATE}} | vegeta report

# Reset Drupal
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-reset:
  -ddev delete -O -y

# --- VALIDATION ---

# Validate kustomize + terraform
[group('validate')]
lint: _lint-kustomize _lint-terraform
  @echo "All validations passed ✓"

# Full AWS validation (creates EKS, runs tests, destroys)
[group('validate')]
validate-aws: _awslogin _terraform-validate
  just setup-eks
  just s3-test
  just s3-restore
  just s3-cleanup
  just destroy-eks
  @echo "AWS validation passed ✓"

# Check required tools
[group('validate')]
prereqs:
  mise install
  @mkdir -p .codeql

# Run SAST analysis (semgrep + CodeQL)
[group('validate')]
[working-directory: '.codeql']
codeql: prereqs
  gh extensions install github/gh-codeql
  -semgrep scan --sarif --output semgrep_results.sarif ..
  gh codeql database create --db-cluster --language=go,python,javascript-typescript --threads=0 --source-root=.. --overwrite codeql-db
  gh codeql database analyze --download --format=sarif-latest --threads=0 --output=go_results.sarif codeql-db/go codeql/go-queries
  gh codeql database analyze --download --format=sarif-latest --threads=0 --output=python_results.sarif codeql-db/python codeql/python-queries
  gh codeql database analyze --download --format=sarif-latest --threads=0 --output=javascript_results.sarif codeql-db/javascript codeql/javascript-queries
  uvx --from sarif-tools sarif csv

# --- UTILITIES ---

# Load test a URL (1000 req/s for 10s)
[group('util')]
vegeta URL:
  echo "GET {{URL}}" | vegeta attack -duration=10s -rate=1000 -insecure | vegeta report

# Install secret from AWS Secrets Manager
[group('util')]
install-secret SECRETID $NAMESPACE $NAME: _awslogin
  kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE
  SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id {{SECRETID}} --query SecretString --output text) \
    envsubst < kustomize/secrets-template.yaml | kubectl apply -f -

# --- PRIVATE HELPERS ---

# Lazy-evaluated AWS helpers (only run when called)
_account:
  @aws sts get-caller-identity | jq -r '.Account'

_bucket:
  @echo "test-$(just _account)"

_username:
  @aws sts get-caller-identity | jq -r '.UserId | split(":")[1]'

_idc-store:
  @aws sso-admin list-instances | jq -r '.Instances[0].IdentityStoreId'

_idc-arn:
  @aws sso-admin list-instances | jq -r '.Instances[0].InstanceArn'

# Infrastructure helpers
_k3d:
  @which k3d > /dev/null || just prereqs
  k3d cluster create tutorials || k3d cluster start tutorials

_deploy-ducklake: _k3d
  kubectl apply -k kustomize-ducklake/overlays/local --server-side

_rclone-lab: _k3d
  helm upgrade --install csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone --set feature.enableInlineVolume=true
  kubectl apply -f rclone/kustomize/deployment.yaml --server-side

_awslogin:
  @which aws > /dev/null || just prereqs
  @aws sts get-caller-identity >/dev/null 2>&1 || aws sso login --use-device-code

_eks-kubeconfig CLUSTER="training01":
  @aws eks update-kubeconfig --name {{CLUSTER}} 2>/dev/null

# Terraform helpers
[working-directory: 'eksauto/terraform']
_terraform-init:
  #!/usr/bin/env bash
  BUCKET="tfstate-$(just _account)"
  REGION="${AWS_REGION:-ap-southeast-2}"
  aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null || {
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
    aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
  }
  terraform init -backend-config="bucket=$BUCKET" -backend-config="region=$REGION"

[working-directory: 'eksauto/terraform']
_terraform-validate: _terraform-init
  terraform validate

_terraform-clean: _awslogin
  -aws eks delete-cluster --name training01
  -aws iam detach-role-policy --role-name eks-s3-test --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
  -aws iam delete-role --role-name eks-s3-test
  -aws logs delete-log-group --log-group-name /aws/eks/training01/cluster
  -aws eks wait cluster-deleted --name training01 || true

# Validation helpers
_lint-kustomize:
  @echo "Validating kustomize..."
  kubectl kustomize kustomize/overlays/local >/dev/null
  kubectl kustomize kustomize/overlays/training01 >/dev/null
  kubectl kustomize kustomize-ducklake/overlays/local >/dev/null
  kubectl kustomize kustomize-s3-pod-identity >/dev/null
  kubectl kustomize kustomize-argocd >/dev/null
  kubectl kustomize kustomize-external-secrets >/dev/null
  kubectl kustomize rclone/kustomize >/dev/null
  kubectl kustomize drupal-cms-perftest/kustomize >/dev/null
  @echo "Kustomize valid ✓"

[working-directory: 'eksauto/terraform']
_lint-terraform:
  @echo "Validating terraform..."
  terraform fmt -check -recursive
  terraform validate
  @echo "Terraform valid ✓"

_validate-ddev: drupal-setup
  curl -sf http://drupal-cms-perftest.ddev.site/ -o /dev/null
  just drupal-loadtest 100 10s
  @echo "DDEV working ✓"

_validate-k3d: deploy-local rclone-test _drupal-csi-test
  @echo "k3d validation passed ✓"

_drupal-csi-test: _rclone-lab
  kubectl apply -k drupal-cms-perftest/kustomize
  kubectl wait --for=condition=Ready pod/drupal-s3-test -n drupal-perf --timeout=120s
  kubectl exec drupal-s3-test -n drupal-perf -- ls -la /srv
  @echo "Drupal CSI working ✓"

# S3 test helpers
_s3-clean:
  -@kubectl delete -k kustomize-s3-pod-identity/jobs 2>/dev/null
  -@kubectl delete -k kustomize-s3-pod-identity 2>/dev/null

_s3-infra:
  helm upgrade --install csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone --namespace veloxpack --create-namespace
  kubectl rollout restart ds/csi-rclone-node -n veloxpack
  kubectl rollout status ds/csi-rclone-node -n veloxpack --timeout=60s

_s3-deploy:
  #!/usr/bin/env bash
  set -euo pipefail
  BUCKET=$(just _bucket)
  echo "Using bucket: $BUCKET"
  kubectl kustomize kustomize-s3-pod-identity | envsubst | kubectl apply -f -
  kubectl create configmap s3-config -n s3-test --from-literal=bucket=$BUCKET --from-literal=region=$AWS_REGION --dry-run=client -o yaml | kubectl apply -f -
  kubectl wait --for=condition=Available deploy/mysql -n s3-test --timeout=120s
  kubectl wait --for=condition=Complete job/sysbench-prepare -n s3-test --timeout=180s || true

_s3-backup:
  kubectl apply -f kustomize-s3-pod-identity/jobs/backup.yaml
  kubectl wait --for=condition=Complete job/backup-to-s3 -n s3-test --timeout=300s
  kubectl logs job/backup-to-s3 -n s3-test | tail -3

_s3-copy:
  kubectl apply -f kustomize-s3-pod-identity/jobs/copy.yaml
  kubectl wait --for=condition=Complete job/rclone-copy -n s3-test --timeout=120s
  kubectl logs job/rclone-copy -n s3-test
