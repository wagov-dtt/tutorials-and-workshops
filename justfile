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
mod observability

# ──── UX / Discovery ────────────────────────────────────────

# Print a concise preflight report for local tools, kind, Linkerd, and AWS identity.
[group('ux')]
doctor:
    @printf "Tools:\n"
    @for tool in docker mise just kind kubectl helm linkerd terraform aws jq yq; do \
      if command -v "$tool" >/dev/null 2>&1; then printf "  %-10s ✓ %s\n" "$tool" "$(command -v "$tool")"; else printf "  %-10s ✗ missing\n" "$tool"; fi; \
    done
    @printf "\nDocker:\n"
    @if docker info >/dev/null 2>&1; then printf "  engine     ✓ running\n"; else printf "  engine     ✗ not reachable\n"; fi
    @printf "\nLocal cluster:\n"
    @if command -v kind >/dev/null 2>&1 && kind get clusters 2>/dev/null | grep -qx tutorials; then printf "  kind       ✓ tutorials\n"; else printf "  kind       - tutorials not created\n"; fi
    @if command -v kubectl >/dev/null 2>&1; then printf "  context    %s\n" "$(kubectl config current-context 2>/dev/null || echo none)"; if kubectl --context kind-tutorials get --raw=/readyz >/dev/null 2>&1; then printf "  api        ✓ kind-tutorials ready\n"; else printf "  api        - kind-tutorials not ready/reachable\n"; fi; else printf "  kubectl    ✗ missing\n"; fi
    @if command -v linkerd >/dev/null 2>&1 && kubectl get namespace linkerd >/dev/null 2>&1; then if linkerd check --proxy -n linkerd >/dev/null 2>&1 || linkerd check >/dev/null 2>&1; then printf "  linkerd    ✓ installed\n"; else printf "  linkerd    ! installed but check failed\n"; fi; else printf "  linkerd    - not installed in current cluster\n"; fi
    @printf "\nAWS:\n"
    @if command -v aws >/dev/null 2>&1; then printf "  profile    %s\n" "${AWS_PROFILE:-default}"; printf "  region     %s\n" "${AWS_REGION:-${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null || echo unset)}}"; if aws sts get-caller-identity >/tmp/tutorials-aws-id.json 2>/dev/null; then printf "  account    ✓ %s\n" "$(jq -r .Account /tmp/tutorials-aws-id.json 2>/dev/null)"; printf "  arn        %s\n" "$(jq -r .Arn /tmp/tutorials-aws-id.json 2>/dev/null)"; else printf "  identity   - not authenticated; run: aws sso login\n"; fi; rm -f /tmp/tutorials-aws-id.json; else printf "  aws        ✗ missing\n"; fi

# Show current local/AWS lab status without creating resources.
[group('ux')]
status:
    @echo "Contexts:"
    @kubectl config get-contexts 2>/dev/null || true
    @echo ""
    @echo "Local namespaces:"
    @kubectl get ns databases rclone collaboration observability 2>/dev/null || true
    @echo ""
    @echo "Helm releases:"
    @helm list -A 2>/dev/null || true

# Print browser URLs and port-forward commands for local labs.
[group('ux')]
urls:
    @echo "Databases:      just databases/urls"
    @echo "rclone:         just rclone/urls"
    @echo "Collaboration:  just collab::urls"
    @echo "Observability:  just observability/urls"
    @echo "Drupal/DDEV:    http://drupal.ddev.site/"

# Print the curated command map.
[group('ux')]
commands:
    @cat COMMANDS.md

# Explain the AWS account/region and paid-resource blast radius before cloud labs.
[group('ux')]
aws-preflight: _awslogin
    @echo "AWS profile: ${AWS_PROFILE:-default}"
    @echo "AWS account: $(just _account)"
    @echo "AWS region:  $(just _aws-region)"
    @echo ""
    @echo "Cloud labs can create paid resources: EKS, EC2/Auto Mode capacity, S3, IAM, CloudWatch/X-Ray."
    @echo "Cleanup commands:"
    @echo "  just s3-pod-identity/clean"
    @echo "  just secrets/clean"
    @echo "  just eksauto/destroy-eks"

# ──── Validate (cross-cutting) ──────────────────────────────

# Check required tools
[group('validate')]
prereqs:
    mise install
    @mkdir -p .codeql

# Fast local render checks for repo-owned Helm charts.
[group('validate')]
check: _check-just _lint-helm-local
    @echo "Fast checks passed ✓"

# Validate Helm charts + terraform + trivy
[group('validate')]
lint: _lint-helm _lint-terraform _lint-trivy
    @echo "All validations passed ✓"

# Security/static analysis checks
[group('validate')]
check-security: _lint-trivy
    @echo "Security checks passed ✓"

# Cloud render/terraform checks. Does not create cloud resources.
[group('validate')]
check-cloud: _lint-terraform _lint-helm-cloud
    @echo "Cloud checks passed ✓"

# Validate all local examples
[group('validate')]
validate-local: lint _validate-ddev _validate-kind
    @echo "Local validation passed ✓"

# Full AWS validation (creates EKS, runs tests, destroys)
[confirm("This will create and destroy an EKS cluster. Continue?")]
[group('validate')]
validate-aws: aws-preflight _awslogin _terraform-validate
    just eksauto::setup-eks
    just eksauto::eks-access
    just s3pi::deploy
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
    just s3pi::clean
    just eksauto::destroy-eks
    @echo "AWS validation passed ✓"

[private]
_check-just:
    just --summary >/dev/null

[private]
_lint-helm-local:
    @echo "Validating local Helm charts..."
    helm lint charts/databases
    helm template databases charts/databases >/dev/null
    helm lint charts/collaboration-stack
    helm template collaboration-stack charts/collaboration-stack >/dev/null
    helm template collaboration-stack charts/collaboration-stack --set sso.enabled=true >/dev/null
    helm template collaboration-stack charts/collaboration-stack --set linkerd.enabled=false >/dev/null
    helm lint charts/rclone-demo
    helm template rclone-demo charts/rclone-demo >/dev/null
    @echo "Local Helm charts valid ✓"

[private]
_lint-helm-cloud:
    @echo "Validating cloud Helm renders..."
    helm lint charts/secrets-demo
    helm template secrets-demo charts/secrets-demo >/dev/null
    helm template secrets-demo charts/secrets-demo --set secretStore.kind=ClusterSecretStore >/dev/null
    helm lint charts/s3-pod-identity
    helm template s3-pod-identity charts/s3-pod-identity \
      --set-string aws.region=$(just _aws-region) \
      --set bucket=test-123456789012 \
      --set s3files.fileSystemId=fs-12345678 >/dev/null
    @echo "Cloud Helm renders valid ✓"

[private]
_lint-helm-observability:
    @echo "Validating observability upstream chart values..."
    helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts >/dev/null 2>&1 || true
    helm repo add vm https://victoriametrics.github.io/helm-charts/ >/dev/null 2>&1 || true
    helm repo add grafana-community https://grafana-community.github.io/helm-charts >/dev/null 2>&1 || true
    helm repo update open-telemetry vm grafana-community >/dev/null
    helm template grafana grafana-community/grafana \
      -f charts/observability/grafana-values.yaml >/dev/null
    helm template otel-collector open-telemetry/opentelemetry-collector \
      -f charts/observability/opentelemetry-collector-values.yaml >/dev/null
    helm template otel-collector open-telemetry/opentelemetry-collector \
      -f charts/observability/opentelemetry-collector-values.yaml \
      -f charts/observability/opentelemetry-collector-cloudwatch-values.yaml >/dev/null
    helm template linkerd-telemetry-collector open-telemetry/opentelemetry-collector \
      -f charts/observability/linkerd-telemetry-collector-values.yaml >/dev/null
    helm template otel-collector open-telemetry/opentelemetry-collector \
      -f charts/observability/opentelemetry-collector-values.yaml \
      -f charts/observability/opentelemetry-collector-s3-values.yaml \
      --set-string extraEnvs[0].name=OBSERVABILITY_S3_BUCKET \
      --set-string extraEnvs[0].value=test-bucket \
      --set-string extraEnvs[1].name=OBSERVABILITY_S3_REGION \
      --set-string extraEnvs[1].value=ap-southeast-2 \
      --set-string extraEnvs[2].name=OBSERVABILITY_S3_BASE_PREFIX \
      --set-string extraEnvs[2].value=local-kind >/dev/null
    helm template victoria-metrics-single vm/victoria-metrics-single \
      -f charts/observability/victoria-metrics-single-values.yaml >/dev/null
    helm template victoria-logs-single vm/victoria-logs-single \
      -f charts/observability/victoria-logs-single-values.yaml >/dev/null
    helm template victoria-traces-single vm/victoria-traces-single \
      -f charts/observability/victoria-traces-single-values.yaml >/dev/null
    @echo "Observability chart values valid ✓"

[private]
_lint-helm: _lint-helm-local _lint-helm-cloud _lint-helm-observability

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
_validate-ddev: drupal::deploy
    curl -sf http://drupal.ddev.site/ -o /dev/null
    just vegeta http://drupal.ddev.site/
    @echo "DDEV working ✓"

[private]
_validate-kind: databases::deploy databases::smoke rclone::deploy rclone::smoke
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
