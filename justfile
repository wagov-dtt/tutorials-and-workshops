set dotenv-load := true
set export := true
set shell := ["bash", "-lc"]

# List all recipes (default)
default:
    @just --list

# Constants (defined in shared.just)
# ──── Docs / Reference ─────────────────────────────────────
# This repo is a collection of standalone mini-projects.
# Each sub-directory has its own justfile with local recipes.
# Run `just --list` to see top-level recipes.
# Run `just <dir>/<recipe>` to call a sub-project recipe,
#    e.g.  just eksauto/setup-eks
#          just restic/backup
# Or cd into a directory and run `just` there.
# Shared helpers (used by all sub-projects and this file)

import 'shared.just'

# Sub-projects as dependencies (hyphen dirs get alias names via `mod NAME 'dir'`)

mod eksauto
mod databases
mod rclone
mod secrets
mod restic
mod s3pi 's3-pod-identity'
mod drupal 'drupal-hugo'
mod collab 'collaboration-stack'

# ──── Validate (cross-cutting) ──────────────────────────────

# Check required tools
[group('validate')]
prereqs:
    mise install
    @mkdir -p .codeql

# Validate Helm charts + terraform + trivy
[group('validate')]
lint: _lint-helm _lint-terraform _lint-trivy
    @echo "All validations passed ✓"

# Validate all local examples
[group('validate')]
validate-local: lint _validate-ddev _validate-kind
    @echo "Local validation passed ✓"

# Full AWS validation (creates EKS, runs tests, destroys)
[confirm("This will create and destroy an EKS cluster. Continue?")]
[group('validate')]
validate-aws: _awslogin _terraform-validate
    just eksauto::setup-eks
    just eksauto::eks-access
    just s3pi::s3-test
    just s3pi::s3-restore
    @echo ""
    @echo "=== Manual inspection pause ==="
    @echo "Cluster: $(kubectl config current-context)"
    @echo "S3 bucket: test-$(just _account)"
    @echo ""
    @echo "Open a new terminal and run:"
    @echo "  just -c k9s                              # Interactive cluster UI"
    @echo "  just -c 'aws s3 ls s3://test-$(just _account)/'  # List bucket contents"
    @echo "  just -c 'aws s3 ls s3://test-$(just _account)/backup1/'  # List backups"
    @echo ""
    @read -p "Press Enter to destroy resources (Ctrl+C to abort)..."
    just s3pi::s3-cleanup
    just eksauto::destroy-eks
    @echo "AWS validation passed ✓"

[private]
_lint-helm:
    @echo "Validating Helm charts..."
    helm lint charts/databases
    helm template databases charts/databases >/dev/null
    helm lint charts/collaboration-stack
    helm template collaboration-stack charts/collaboration-stack >/dev/null
    helm template collaboration-stack charts/collaboration-stack --set linkerd.enabled=false >/dev/null
    helm lint charts/rclone-demo
    helm template rclone-demo charts/rclone-demo >/dev/null
    helm lint charts/secrets-demo
    helm template secrets-demo charts/secrets-demo >/dev/null
    helm lint charts/s3-pod-identity
    helm template s3-pod-identity charts/s3-pod-identity \
      --set aws.region=us-east-1 \
      --set bucket=test-123456789012 \
      --set s3files.fileSystemId=fs-12345678 >/dev/null
    @echo "Helm charts valid ✓"

[private]
[working-directory('eksauto/terraform')]
_lint-terraform:
    @echo "Validating terraform..."
    terraform fmt -check -recursive
    terraform init -backend=false -upgrade
    terraform validate
    @echo "Terraform valid ✓"

[private]
_lint-trivy:
    @echo "Running trivy..."
    trivy config --exit-code 1 --ignorefile eksauto/terraform/.trivyignore --skip-dirs .terraform eksauto/terraform
    trivy config --exit-code 1 --ignorefile .trivyignore charts
    @echo "Trivy passed ✓"

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

[private]
_validate-ddev: drupal::drupal-setup
    curl -sf http://drupal.ddev.site/ -o /dev/null
    just vegeta http://drupal.ddev.site/
    @echo "DDEV working ✓"

[private]
_validate-kind: databases::deploy rclone::rclone-test
    @echo "kind validation passed ✓"

# ──── Utilities (cross-cutting) ─────────────────────────────

# Load test a URL (640 req/s for 10s)
[group('util')]
vegeta URL:
    echo "GET {{ URL }}" | vegeta attack -duration=10s -rate=640 -insecure | vegeta report

# Install secret from AWS Secrets Manager
[group('util')]
install-secret SECRETID $NAMESPACE $NAME: _awslogin
    kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id {{ SECRETID }} --query SecretString --output text) \
      envsubst < charts/databases/secrets-template.yaml | kubectl apply -f -
