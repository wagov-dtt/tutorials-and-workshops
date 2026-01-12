set dotenv-load
set export
set shell := ["bash", "-lc"]
set unstable

# Constants
default_cluster := "training01"

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
ducklake-test: _ducklake
  uv run ducklake_test.py

# rclone CSI demo (S3 mount + filebrowser)
[group('local')]
rclone-test: _rclone
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
[working-directory('eksauto/terraform')]
setup-eks: _awslogin _terraform-init
  terraform apply -auto-approve || { terraform destroy -auto-approve; terraform apply -auto-approve; }
  aws eks update-kubeconfig --name $(terraform output -raw cluster_name)
  kubectl get nodes || echo "Nodes starting (EKS Auto Mode)"

# Destroy EKS cluster
[group('eks')]
[confirm("This will destroy the EKS cluster. Continue?")]
[working-directory('eksauto/terraform')]
destroy-eks: _awslogin
  -aws eks delete-capability --cluster-name training01 --capability-name argocd
  @sleep 30
  terraform destroy -auto-approve

# Add current SSO user as cluster admin
[group('eks')]
eks-access CLUSTER=default_cluster: _awslogin
  aws eks create-access-entry --cluster-name {{CLUSTER}} --principal-arn $(just _sso-role-arn) --type STANDARD || true
  aws eks associate-access-policy --cluster-name {{CLUSTER}} --principal-arn $(just _sso-role-arn) \
    --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster

# Deploy core manifests to EKS
[group('eks')]
deploy CLUSTER=default_cluster: _awslogin (_eks-kubeconfig CLUSTER)
  kubectl apply -k kustomize/overlays/{{CLUSTER}}

# S3 Pod Identity demo (MySQL → S3 → rclone → restore)
[group('eks')]
s3-test: _awslogin _eks-kubeconfig
  # Cleanup previous resources
  -kubectl delete -k s3-pod-identity/jobs 2>/dev/null
  -kubectl delete -k s3-pod-identity 2>/dev/null
  
  # Deploy rclone CSI driver
  @echo "Deploying rclone CSI driver..."
  helm upgrade --install csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone --namespace veloxpack --create-namespace
  kubectl rollout restart ds/csi-rclone-node -n veloxpack
  kubectl rollout status ds/csi-rclone-node -n veloxpack --timeout=60s
  
  # Deploy MySQL with Pod Identity
  @echo "Deploying MySQL with Pod Identity..."
  kubectl kustomize s3-pod-identity | envsubst | kubectl apply -f -
  kubectl create configmap s3-config -n s3-test \
    --from-literal=bucket=$(just _bucket) --from-literal=region=$AWS_REGION \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl wait --for=condition=Available deploy/mysql -n s3-test --timeout=120s
  -kubectl wait --for=condition=Complete job/sysbench-prepare -n s3-test --timeout=180s
  
  # Backup MySQL to S3
  @echo "Backing up MySQL to S3..."
  kubectl apply -f s3-pod-identity/jobs/backup.yaml
  kubectl wait --for=condition=Complete job/backup-to-s3 -n s3-test --timeout=300s
  kubectl logs job/backup-to-s3 -n s3-test | tail -3
  
  # Copy backup via rclone CSI mount
  @echo "Testing rclone CSI mount..."
  kubectl apply -f s3-pod-identity/jobs/copy.yaml
  kubectl wait --for=condition=Complete job/rclone-copy -n s3-test --timeout=120s
  kubectl logs job/rclone-copy -n s3-test
  
  @echo "S3 Pod Identity test complete ✓"
  @echo "Run 'just s3-restore' to test restore, 'just s3-cleanup' when done"

# Restore MySQL backup from S3
[group('eks')]
s3-restore: _eks-kubeconfig
  -kubectl delete job restore-from-s3 -n s3-test
  kubectl apply -f s3-pod-identity/jobs/restore.yaml
  kubectl wait --for=condition=Complete job/restore-from-s3 -n s3-test --timeout=300s
  kubectl logs job/restore-from-s3 -n s3-test -c mysqlsh-restore | tail -10

# Cleanup S3 Pod Identity resources
[group('eks')]
s3-cleanup:
  -kubectl delete -k s3-pod-identity/jobs
  -kubectl delete -k s3-pod-identity
  -helm uninstall csi-rclone -n veloxpack

# --- ARGOCD ---

# Create ArgoCD EKS capability
[group('argocd')]
argocd-create CLUSTER=default_cluster: _awslogin (_argocd-create-inner CLUSTER `just _idc-arn` `just _account`)

[private]
_argocd-create-inner CLUSTER IDC ACCOUNT:
  {{ assert(IDC != "null", "Identity Center not configured") }}
  aws eks create-capability --cluster-name {{CLUSTER}} --capability-name argocd --type ARGOCD \
    --role-arn "arn:aws:iam::{{ACCOUNT}}:role/eks-argocd-capability" --delete-propagation-policy RETAIN \
    --configuration '{"argoCd":{"awsIdc":{"idcInstanceArn":"{{IDC}}","idcRegion":"'"$AWS_REGION"'"}}}'
  just _argocd-wait {{CLUSTER}}

[private]
_argocd-wait CLUSTER:
  @while true; do \
    STATUS=`aws eks describe-capability --cluster-name {{CLUSTER}} --capability-name argocd | jq -r '.capability.status'`; \
    echo "Status: $$STATUS"; \
    [ "$$STATUS" = "ACTIVE" ] && exit 0; \
    sleep 10; \
  done

# Delete ArgoCD capability
[group('argocd')]
argocd-delete CLUSTER=default_cluster: _awslogin
  -aws eks delete-capability --cluster-name {{CLUSTER}} --capability-name argocd

# Deploy ArgoCD ApplicationSet
[group('argocd')]
argocd-deploy CLUSTER=default_cluster: _awslogin (_eks-kubeconfig CLUSTER)
  kubectl apply -k argocd
  @echo "ApplicationSet deployed ✓"

# Get ArgoCD UI URL (auto-adds current user as admin)
[group('argocd')]
argocd-ui CLUSTER=default_cluster: _awslogin (_argocd-ui-inner CLUSTER `just _username` `just _idc-store`)

[private]
_argocd-ui-inner CLUSTER USERNAME IDC_STORE:
  @just _argocd-add-admin {{CLUSTER}} {{USERNAME}} {{IDC_STORE}}
  @aws eks describe-capability --cluster-name {{CLUSTER}} --capability-name argocd | jq -r '.capability.configuration.argoCd.serverUrl'

[private]
_argocd-add-admin CLUSTER USERNAME IDC_STORE:
  @USER_ID=$$(aws identitystore get-user-id --identity-store-id "{{IDC_STORE}}" \
    --alternate-identifier '{"UniqueAttribute":{"AttributePath":"userName","AttributeValue":"{{USERNAME}}"}}' 2>/dev/null | jq -r '.UserId // empty'); \
  if [ -n "$$USER_ID" ]; then \
    CURRENT=$$(aws eks describe-capability --cluster-name {{CLUSTER}} --capability-name argocd | jq -r '.capability.configuration.argoCd // {}'); \
    if ! echo "$$CURRENT" | jq -e --arg id "$$USER_ID" '.rbacRoleMappings[]?.identities[]?.id == $$id' >/dev/null 2>&1; then \
      echo "Adding {{USERNAME}} as admin..."; \
      aws eks update-capability --cluster-name {{CLUSTER}} --capability-name argocd \
        --configuration '{"argoCd":{"rbacRoleMappings":{"addOrUpdateRoleMappings":[{"role":"ADMIN","identities":[{"id":"'"$$USER_ID"'","type":"SSO_USER"}]}]}}}' >/dev/null; \
      sleep 3; \
    fi; \
  fi

# Cleanup ArgoCD ApplicationSet
[group('argocd')]
argocd-cleanup:
  -kubectl delete -k argocd

# --- EXTERNAL SECRETS ---

# Deploy External Secrets Operator
[group('secrets')]
secrets-deploy: _awslogin _eks-kubeconfig
  helm upgrade --install external-secrets oci://ghcr.io/external-secrets/charts/external-secrets \
    --namespace external-secrets --create-namespace --set installCRDs=true
  kubectl wait --for=condition=Available deploy/external-secrets -n external-secrets --timeout=180s
  kubectl rollout restart deploy -n external-secrets
  kubectl rollout status deploy/external-secrets -n external-secrets --timeout=60s
  kubectl apply -k secrets
  @echo "External Secrets deployed ✓"

# Test External Secrets sync
[group('secrets')]
secrets-test:
  kubectl get externalsecret -n secrets-demo
  @kubectl get secret db-creds -n secrets-demo -o jsonpath='{.data.username}' | base64 -d && echo

# Cleanup External Secrets
[group('secrets')]
secrets-cleanup:
  -kubectl delete -k secrets
  -helm uninstall external-secrets -n external-secrets
  -kubectl delete namespace external-secrets secrets-demo

# --- DRUPAL ---

# Setup Drupal CMS with FrankenPHP
[group('drupal')]
[working-directory('drupal')]
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

# Run search performance tests
[group('drupal')]
[working-directory('drupal')]
drupal-test:
  ddev drush search-api:rebuild-tracker content
  ddev drush search-api:index --batch-size=1000
  ddev drush php:script scripts/search_performance_test.php

# Reset Drupal (delete and start fresh)
[group('drupal')]
[confirm("This will delete the Drupal instance. Continue?")]
[working-directory('drupal')]
drupal-reset:
  -ddev delete -O -y

# --- VALIDATION ---

# Validate kustomize + terraform + trivy + caddyfile
[group('validate')]
lint:
  @echo "Validating kustomize..." && \
    kubectl kustomize kustomize/overlays/local kustomize/overlays/training01 ducklake/overlays/local \
      s3-pod-identity argocd secrets rclone/base drupal/kustomize >/dev/null && \
    echo "Kustomize valid ✓"
  @echo "Validating terraform..." && \
    cd eksauto/terraform && terraform fmt -check -recursive && terraform init -backend=false -upgrade && terraform validate && \
    echo "Terraform valid ✓"
  @echo "Running trivy..." && \
    trivy config --exit-code 1 --ignorefile eksauto/terraform/.trivyignore --skip-dirs .terraform eksauto/terraform && \
    trivy config --exit-code 1 --ignorefile .trivyignore kustomize argocd ducklake s3-pod-identity secrets rclone drupal/kustomize && \
    echo "Trivy passed ✓"
  @echo "Validating Caddyfile..." && caddy fmt --diff drupal/Caddyfile && echo "Caddyfile valid ✓"
  @echo "All validations passed ✓"

# Full AWS validation (creates EKS, runs tests, destroys)
[group('validate')]
[confirm("This will create and destroy an EKS cluster. Continue?")]
validate-aws: _awslogin _terraform-validate
  just setup-eks
  just eks-access
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
[working-directory('.codeql')]
codeql: prereqs
  gh extensions install github/gh-codeql
  -semgrep scan --sarif --output semgrep_results.sarif ..
  gh codeql database create --db-cluster --language=go,python,javascript-typescript --threads=0 --source-root=.. --overwrite codeql-db
  gh codeql database analyze --download --format=sarif-latest --threads=0 --output=go_results.sarif codeql-db/go codeql/go-queries
  gh codeql database analyze --download --format=sarif-latest --threads=0 --output=python_results.sarif codeql-db/python codeql/python-queries
  gh codeql database analyze --download --format=sarif-latest --threads=0 --output=javascript_results.sarif codeql-db/javascript codeql/javascript-queries
  uvx --from sarif-tools sarif csv

# --- GOOSE + BEDROCK ---
GOOSE_DISABLE_KEYRING := env_var_or_default("GOOSE_DISABLE_KEYRING", "true")
LITELLM_CONFIG := justfile_directory() / "litellm_goose.yaml"

# Start LiteLLM proxy server (for manual use or debugging)
# Starts a local proxy that translates OpenAI API → AWS Bedrock API
# Uses AWS credentials from environment (requires: aws sso login)
# Config: litellm_goose.yaml defines 4 Bedrock models
# Access: http://127.0.0.1:54000 (OpenAI-compatible endpoint)
[group('goose')]
litellm: _awslogin
  @echo "Starting LiteLLM with config: {{LITELLM_CONFIG}}"
  uvx --with boto3 litellm[proxy] --config {{LITELLM_CONFIG}} --host 127.0.0.1 --port 54000

# Install Goose configuration to ~/.config/goose/config.yaml
# Sets up Goose to use local LiteLLM proxy with claude-sonnet-4-5 as default
# Enables: developer, chatrecall, extensionmanager, todo, skills, computercontroller
# Run this once after installing Goose, then start LiteLLM and run Goose manually
[group('goose')]
configure-goose:
  @mkdir -p ~/.config/goose
  @cp -i goose-config.yaml ~/.config/goose/config.yaml
  @echo "Goose configured ✓"
  @echo "Config: ~/.config/goose/config.yaml"
  @echo "Next: Start LiteLLM proxy with 'just litellm', then run 'goose session' in another terminal"

# --- UTILITIES ---

# Load test a URL (640 req/s for 10s)
[group('util')]
vegeta URL:
  echo "GET {{URL}}" | vegeta attack -duration=10s -rate=640 -insecure | vegeta report

# Install secret from AWS Secrets Manager
[group('util')]
install-secret SECRETID $NAMESPACE $NAME: _awslogin
  kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE
  SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id {{SECRETID}} --query SecretString --output text) \
    envsubst < kustomize/secrets-template.yaml | kubectl apply -f -

# --- PRIVATE HELPERS ---

[private]
_account:
  @aws sts get-caller-identity | jq -r '.Account'

[private]
_bucket:
  @echo "test-$(just _account)"

[private]
_username:
  @aws sts get-caller-identity | jq -r '.UserId | split(":")[1]'

[private]
_idc-store:
  @aws sso-admin list-instances | jq -r '.Instances[0].IdentityStoreId'

[private]
_idc-arn:
  @aws sso-admin list-instances | jq -r '.Instances[0].InstanceArn'

[private]
_sso-role-arn:
  @ROLE_NAME=$(aws sts get-caller-identity | jq -r '.Arn | split("/")[1]') && \
    aws iam get-role --role-name $ROLE_NAME | jq -r '.Role.Arn'

[private]
_k3d:
  @which k3d > /dev/null || just prereqs
  k3d cluster create tutorials || k3d cluster start tutorials

[private]
_ducklake: _k3d
  kubectl apply -k ducklake/overlays/local --server-side

[private]
_rclone: _k3d
  helm upgrade --install csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone --set feature.enableInlineVolume=true
  kubectl apply -f rclone/base/deployment.yaml --server-side

[private]
_awslogin:
  @which aws > /dev/null || just prereqs
  @aws sts get-caller-identity >/dev/null 2>&1 || aws sso login --use-device-code

[private]
_eks-kubeconfig CLUSTER=default_cluster:
  aws eks update-kubeconfig --name {{CLUSTER}}
  yq -i '(.users[] | select(.name | test("{{CLUSTER}}")) | .user.exec.command) = "'$(which aws)'"' ~/.kube/config
  kubectl cluster-info

[private]
[working-directory('eksauto/terraform')]
_terraform-init:
  -aws s3api create-bucket --bucket tfstate-$(just _account) --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null
  terraform init -backend-config="bucket=tfstate-$(just _account)" -backend-config="region=$AWS_REGION"

[private]
[working-directory('eksauto/terraform')]
_terraform-validate: _terraform-init
  terraform validate

[private]
_validate-ddev: drupal-setup
  curl -sf http://drupal.ddev.site/ -o /dev/null
  just vegeta http://drupal.ddev.site/
  @echo "DDEV working ✓"

[private]
_validate-k3d: deploy-local rclone-test _drupal-csi
  @echo "k3d validation passed ✓"

[private]
_drupal-csi: _rclone
  kubectl apply -k drupal/kustomize
  kubectl wait --for=condition=Ready pod/drupal-s3-test -n drupal-perf --timeout=120s
  kubectl exec drupal-s3-test -n drupal-perf -- ls -la /srv
  @echo "Drupal CSI working ✓"
