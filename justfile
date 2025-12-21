set dotenv-load
set export
set shell := ["bash", "-lc"]

# Derived variables from environment
ACCOUNT := `aws sts get-caller-identity --query Account --output text 2>/dev/null || echo ""`
BUCKET := "test-" + ACCOUNT

# Choose a task to run
default:
  just --choose

# Show key workflows
help:
  @echo "=== Core Workflows ==="
  @echo "  just deploy-local          # k3d + databases (Postgres, MySQL, MongoDB, ES)"
  @echo "  just deploy                # EKS training01 + core kustomize"
  @echo "  just setup-eks             # Create EKS cluster via Terraform (~$80-100/mo!)"
  @echo "  just destroy-eks           # Destroy EKS cluster and all resources"
  @echo ""
  @echo "=== Examples ==="
  @echo "  just s3-pod-identity-test  # EKS: MySQL backup → S3 → rclone → restore"
  @echo "  just argocd-deploy         # EKS: ArgoCD ApplicationSet (enabled by default)"
  @echo "  just external-secrets-deploy # EKS: External Secrets Operator + AWS SM"
  @echo "  just ducklake-test         # k3d: DuckLake with NY Taxi data"
  @echo "  just rclone-lab            # k3d: rclone CSI S3 mount + filebrowser"
  @echo ""
  @echo "=== Validation ==="
  @echo "  just lint                  # Validate kustomize manifests"
  @echo "  just validate-local        # Full local validation (DDEV + k3d)"
  @echo "  just validate-aws          # AWS validation (creates EKS cluster!)"
  @echo "  just prereqs               # Check required tools"
  @echo ""
  @echo "  just drupal-setup          # Install Drupal CMS with FrankenPHP"
  @echo "  just drupal-generate       # Generate 100k test articles"
  @echo "  just drupal-test           # Run search performance tests"

# Validate all kustomize manifests and terraform
lint: _lint-kustomize _lint-terraform
  @echo ""
  @echo "All validations passed ✓"

_lint-kustomize:
  @echo "=== Validating kustomize manifests ==="
  kubectl kustomize kustomize/overlays/local > /dev/null
  kubectl kustomize kustomize/overlays/training01 > /dev/null
  kubectl kustomize kustomize-ducklake/overlays/local > /dev/null
  kubectl kustomize kustomize-s3-pod-identity > /dev/null
  kubectl kustomize kustomize-argocd > /dev/null
  kubectl kustomize kustomize-external-secrets > /dev/null
  kubectl kustomize rclone/kustomize > /dev/null
  kubectl kustomize drupal-cms-perftest/kustomize > /dev/null
  @echo "Kustomize manifests valid ✓"

[working-directory: 'eksauto/terraform']
_lint-terraform:
  @echo "=== Validating Terraform ==="
  terraform fmt -check -recursive
  terraform validate
  @echo "Terraform valid ✓"

# Local validation: DDEV + k3d tests (no AWS credentials needed)
validate-local: lint _validate-ddev _validate-k3d
  @echo ""
  @echo "=== Local validations passed ✓ ==="

_validate-ddev: drupal-setup
  @echo ""
  @echo "=== Load testing FrankenPHP (10s @ 100 req/s) ==="
  echo "GET https://drupal-cms-perftest.ddev.site/" | vegeta attack -duration=10s -rate=100 -insecure | vegeta report
  @echo "DDEV Drupal setup working ✓"

_validate-k3d: deploy-local rclone-test ducklake-test drupal-csi-test
  @echo ""
  @echo "=== k3d validations passed ✓ ==="

# AWS validation: EKS cluster + S3 Pod Identity tests (creates real resources!)
validate-aws: awslogin _terraform-validate
  @echo ""
  @echo "=== Running full AWS validation (EKS + S3 Pod Identity) ==="
  just setup-eks
  just s3-pod-identity-test
  just s3-restore
  @echo ""
  @echo "=== AWS tests passed, cleaning up ==="
  just s3-pod-identity-cleanup
  just destroy-eks
  @echo "AWS validation passed ✓"

# Check required tools are installed (via mise)
prereqs:
  mise install
  @mkdir -p .codeql

# Login to aws using SSO
@awslogin:
  which aws > /dev/null || just prereqs
  # make sure aws logged in
  aws sts get-caller-identity > /dev/null || aws sso login --use-device-code || \
  (echo please run '"aws configure sso --use-device-code"' and add AWS_PROFILE/AWS_REGION to your .env file && exit 1)

# Create an eks cluster for testing using Terraform
# EKS Auto Mode includes envelope encryption by default using AWS KMS
# Pod Identity associations are pre-created for s3-test and veloxpack namespaces
[working-directory: 'eksauto/terraform']
setup-eks: awslogin _terraform-init
  #!/usr/bin/env bash
  set -euo pipefail
  # Try apply first, if it fails due to existing resources, destroy and retry
  if ! terraform apply -auto-approve 2>&1; then
    echo "=== Apply failed, attempting terraform destroy first ==="
    terraform destroy -auto-approve || just _terraform-clean
    terraform apply -auto-approve
  fi
  # Configure kubectl for the new cluster
  echo "=== Configuring kubectl ==="
  aws eks update-kubeconfig --name $(terraform output -raw cluster_name)
  echo "=== Verifying cluster access ==="
  kubectl get nodes || echo "Nodes may take a few minutes to appear (EKS Auto Mode)"

# Validate terraform config
[working-directory: 'eksauto/terraform']
_terraform-validate: _terraform-init
  @echo "=== Validating Terraform ==="
  terraform validate

# Initialize terraform with S3 backend (creates state bucket if missing)
[working-directory: 'eksauto/terraform']
_terraform-init:
  #!/usr/bin/env bash
  BUCKET="tfstate-{{ACCOUNT}}"
  REGION="${AWS_REGION:-ap-southeast-2}"
  # Create state bucket if missing (versioning enabled for state recovery)
  if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
    echo "Creating state bucket: $BUCKET"
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
    aws s3api put-bucket-versioning --bucket "$BUCKET" \
      --versioning-configuration Status=Enabled
  fi
  terraform init -backend-config="bucket=$BUCKET" -backend-config="region=$REGION"

# Clean up orphaned AWS resources before terraform apply (training repo - ok to nuke)
_terraform-clean: awslogin
  @echo "=== Cleaning orphaned resources ==="
  -aws eks delete-cluster --name training01 2>/dev/null
  -aws iam detach-role-policy --role-name eks-s3-test --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null
  -aws iam delete-role --role-name eks-s3-test 2>/dev/null
  -aws logs delete-log-group --log-group-name /aws/eks/training01/cluster 2>/dev/null
  @echo "Waiting for EKS cluster deletion (if any)..."
  -aws eks wait cluster-deleted --name training01 2>/dev/null || true

# Destroy EKS cluster and all associated resources
[working-directory: 'eksauto/terraform']
destroy-eks: awslogin
  terraform destroy -auto-approve

# Ensure kubectl is configured for EKS cluster
_eks-kubeconfig CLUSTER="training01":
  @aws eks update-kubeconfig --name {{CLUSTER}}

# Install manifests for a given cluster, create the cluster if one is not connected.
deploy CLUSTER="training01": (_eks-kubeconfig CLUSTER)
  kubectl apply -k kustomize/overlays/{{CLUSTER}}

# Simplest docker hosted k8s cluster (traefik included by default)
k3d:
  @which k3d > /dev/null || just prereqs
  k3d cluster create tutorials || k3d cluster start tutorials

# Deploy databases + debug pod to local k3d cluster
deploy-local: k3d
  kubectl apply -k kustomize/overlays/local --server-side

# Deploy DuckLake stack (Postgres + rclone-s3) to local k3d cluster
deploy-ducklake: k3d
  kubectl apply -k kustomize-ducklake/overlays/local --server-side

# Runs through a basic test using local k3d hosted just dpostgres/s3
ducklake-test: deploy-ducklake
  uv run ducklake_test.py

# rclone CSI demo (S3 server + filebrowser with CSI mount)
rclone-lab: k3d
  helm upgrade --install csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone --set feature.enableInlineVolume=true
  kubectl apply -f rclone/kustomize/deployment.yaml --server-side

# Smoke test for rclone CSI - verify filebrowser can access S3 mount
rclone-test: rclone-lab
  @echo "=== Waiting for filebrowser pods ==="
  kubectl wait --for=condition=Ready pod -l app=filebrowser --timeout=120s
  @echo "=== Checking S3 mount in filebrowser pod ==="
  kubectl exec deploy/filebrowser -- ls -la /srv
  @echo "=== rclone CSI mount working ✓ ==="

# Smoke test for Drupal CSI mount (requires rclone-lab first)
drupal-csi-test: rclone-lab
  kubectl apply -k drupal-cms-perftest/kustomize
  @echo "=== Waiting for drupal-s3-test pod ==="
  kubectl wait --for=condition=Ready pod/drupal-s3-test -n drupal-perf --timeout=120s
  @echo "=== Checking S3 mount in Drupal test pod ==="
  kubectl exec drupal-s3-test -n drupal-perf -- ls -la /srv
  @echo "=== Drupal CSI mount working ✓ ==="

# S3 Pod Identity demo: MySQL + sysbench + backup to S3 + rclone copy + CSI mount
# Pod Identity associations are pre-created by Terraform (s3-test + veloxpack namespaces)
s3-pod-identity-test: awslogin _eks-kubeconfig (_s3-clean) (_s3-infra) (_s3-deploy) (_s3-backup) (_s3-copy) (_s3-debug)

_s3-clean:
  -@kubectl delete -k kustomize-s3-pod-identity/jobs 2>/dev/null
  -@kubectl delete -k kustomize-s3-pod-identity 2>/dev/null

# Install rclone CSI driver (IAM role + S3 bucket created by Terraform)
_s3-infra:
  @echo "=== Installing rclone CSI driver ==="
  helm upgrade --install csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone --namespace veloxpack --create-namespace
  @echo "=== Restarting CSI driver to pick up Pod Identity credentials ==="
  kubectl rollout restart ds/csi-rclone-node -n veloxpack
  kubectl rollout status ds/csi-rclone-node -n veloxpack --timeout=60s

_s3-deploy:
  @echo "Using bucket: {{BUCKET}}"
  kubectl kustomize kustomize-s3-pod-identity | envsubst | kubectl apply -f -
  kubectl create configmap s3-config -n s3-test --from-literal=bucket={{BUCKET}} --from-literal=region=$AWS_REGION --dry-run=client -o yaml | kubectl apply -f -
  kubectl wait --for=condition=Available deploy/mysql -n s3-test --timeout=120s
  @echo "=== Running sysbench ==="
  -kubectl wait --for=condition=Complete job/sysbench-prepare -n s3-test --timeout=180s

_s3-backup:
  @echo "=== Backing up MySQL to S3 ==="
  kubectl apply -f kustomize-s3-pod-identity/jobs/backup.yaml
  kubectl wait --for=condition=Complete job/backup-to-s3 -n s3-test --timeout=300s
  kubectl logs job/backup-to-s3 -n s3-test | tail -3

_s3-copy:
  @echo "=== Copying backup1 to backup2 ==="
  kubectl apply -f kustomize-s3-pod-identity/jobs/copy.yaml
  kubectl wait --for=condition=Complete job/rclone-copy -n s3-test --timeout=120s
  kubectl logs job/rclone-copy -n s3-test

# Restore backup to different database name (run after s3-pod-identity-test)
s3-restore: _eks-kubeconfig
  @echo "=== Restoring backup to sbtest_restored ==="
  -kubectl delete job restore-from-s3 -n s3-test
  kubectl apply -f kustomize-s3-pod-identity/jobs/restore.yaml
  kubectl wait --for=condition=Complete job/restore-from-s3 -n s3-test --timeout=300s
  kubectl logs job/restore-from-s3 -n s3-test -c mysqlsh-restore | tail -20

_s3-debug:
  @echo "=== Debug pod with S3 CSI mount ==="
  -kubectl wait --for=condition=Ready pod/debug -n s3-test --timeout=120s
  @echo "Run: kubectl exec -it debug -n s3-test -- sh"
  @echo "Then: ls /mnt/s3"

# Cleanup pod identity test K8s resources (IAM role + S3 bucket managed by Terraform)
s3-pod-identity-cleanup:
  -kubectl delete -k kustomize-s3-pod-identity/jobs
  -kubectl delete -k kustomize-s3-pod-identity
  -helm uninstall csi-rclone -n veloxpack

# Deploy ArgoCD ApplicationSet (ArgoCD capability enabled by default with setup-eks)
argocd-deploy: awslogin _eks-kubeconfig
  @echo "=== Deploying ApplicationSet ==="
  kubectl apply -k kustomize-argocd
  @echo "ArgoCD ApplicationSet deployed ✓"
  @echo "View in ArgoCD UI: $(aws eks describe-capability --cluster-name training01 --capability-name argocd --query 'capability.argoCdDetail.webServerEndpoint' --output text 2>/dev/null || echo 'run just argocd-ui')"

# Get ArgoCD UI URL
argocd-ui:
  @aws eks describe-capability --cluster-name training01 --capability-name argocd \
    --query 'capability.argoCdDetail.webServerEndpoint' --output text

# Cleanup ArgoCD ApplicationSet
argocd-cleanup:
  -kubectl delete -k kustomize-argocd

# Deploy External Secrets Operator (EKS)
external-secrets-deploy: awslogin _eks-kubeconfig
  @echo "=== Installing External Secrets Operator ==="
  helm upgrade --install external-secrets oci://ghcr.io/external-secrets/charts/external-secrets \
    --namespace external-secrets --create-namespace \
    --set installCRDs=true
  kubectl wait --for=condition=Available deploy/external-secrets -n external-secrets --timeout=180s
  @echo "=== Restarting to pick up Pod Identity ==="
  kubectl rollout restart deploy -n external-secrets
  kubectl rollout status deploy/external-secrets -n external-secrets --timeout=60s
  @echo "=== Deploying ClusterSecretStore + ExternalSecret ==="
  kubectl apply -k kustomize-external-secrets
  @echo "External Secrets Operator deployed ✓"

# Test External Secrets sync
external-secrets-test:
  @echo "=== Checking ExternalSecret status ==="
  kubectl get externalsecret -n secrets-demo
  @echo "=== Checking synced K8s Secret ==="
  kubectl get secret db-creds -n secrets-demo -o jsonpath='{.data.username}' | base64 -d && echo

# Cleanup External Secrets Operator
external-secrets-cleanup:
  -kubectl delete -k kustomize-external-secrets
  -helm uninstall external-secrets -n external-secrets
  -kubectl delete namespace external-secrets secrets-demo

# Retreives a secret from AWS Secrets Manager as JSON and saves to kubernetes
install-secret SECRETID $NAMESPACE $NAME: awslogin
  kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE
  cat kustomize/secrets-template.yaml | \
  SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id {{SECRETID}} --query SecretString --output text) \
  envsubst | kubectl apply -f -

# Load test a site with vegeta (HTTP load testing tool)
# Usage: just vegeta https://example.com
# Runs 1000 req/s for 10s, reports latency percentiles and success rate
vegeta URL:
  echo "GET {{URL}}" | vegeta attack -duration=10s -rate=1000 -insecure | vegeta report

# === Drupal CMS (FrankenPHP + DDEV) ===

# Setup Drupal CMS with FrankenPHP and search/news recipes
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-setup:
  ddev add-on get ddev/ddev-frankenphp
  ddev dotenv set .ddev/.env.web --frankenphp-custom-extensions="apcu opcache intl bcmath"
  ddev start
  ddev composer install
  ddev drush site:install --account-name=admin --account-pass=admin -y
  ddev drush recipe ../recipes/drupal_cms_starter
  ddev drush recipe ../recipes/drupal_cms_search
  ddev drush recipe ../recipes/drupal_cms_news

# Start Drupal DDEV containers
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-start:
  ddev start

# Stop Drupal DDEV containers
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-stop:
  ddev stop

# Get Drupal admin login link
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-login:
  ddev drush user:login

# Generate test content (100k articles)
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

# Clear test content
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-clear:
  ddev drush sql:query "DELETE FROM node WHERE type='news'"
  ddev drush search-api:clear

# Full workflow: generate + test
[group('drupal')]
drupal-full-test:
  just drupal-generate
  just drupal-test

# Reset Drupal (delete DDEV project)
[group('drupal')]
[working-directory: 'drupal-cms-perftest']
drupal-reset:
  -ddev delete -O -y

# Run semgrep/CodeQL (SAST) analysis locally and output results to CSV
[working-directory: '.codeql']
codeql: prereqs
    gh extensions install github/gh-codeql
    -semgrep scan --sarif --output semgrep_results.sarif ..
    gh codeql database create --db-cluster --language=go,python,javascript-typescript --threads=0 --source-root=.. --overwrite codeql-db
    gh codeql database analyze --download --format=sarif-latest --threads=0 --output=go_results.sarif codeql-db/go codeql/go-queries
    gh codeql database analyze --download --format=sarif-latest --threads=0 --output=python_results.sarif codeql-db/python codeql/python-queries
    gh codeql database analyze --download --format=sarif-latest --threads=0 --output=javascript_results.sarif codeql-db/javascript codeql/javascript-queries
    uvx --from sarif-tools sarif csv
