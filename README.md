# tutorials-and-workshops

Concise DevOps/K8s examples. See [DevSecOps Induction](https://soc.cyber.wa.gov.au/training/devsecops-induction/) for structured training.

```bash
just              # List all recipes
just prereqs      # Install tools via mise
```

## Quick Start

### Local (no AWS)

```bash
just deploy-local   # k3d + databases (Postgres, MySQL, MongoDB, ES)
just ducklake-test  # DuckLake with NY Taxi data
just rclone-test    # rclone CSI S3 mount
just validate-local # Run all local tests
```

### EKS (requires AWS)

```bash
just setup-eks      # Create cluster (~$80-100/mo)
just deploy         # Deploy core manifests
just s3-test        # S3 Pod Identity demo
just destroy-eks    # Destroy when done
```

## Examples

| Directory | Purpose |
|-----------|---------|
| [kustomize/](kustomize/) | Base K8s manifests with overlays |
| [s3-pod-identity/](s3-pod-identity/) | EKS Pod Identity: MySQL → S3 → rclone |
| [argocd/](argocd/) | ArgoCD ApplicationSets |
| [secrets/](secrets/) | External Secrets + AWS Secrets Manager |
| [ducklake/](ducklake/) | DuckLake (DuckDB + S3) |
| [rclone/](rclone/) | rclone CSI driver examples |
| [eksauto/](eksauto/) | EKS Auto Mode via Terraform |
| [drupal/](drupal/) | Drupal CMS with DDEV/FrankenPHP |

## ArgoCD (EKS Capability)

ArgoCD uses AWS Identity Center for SSO authentication:

```bash
just argocd-create  # Create capability (requires Identity Center)
just argocd-ui      # Get URL (auto-adds current user as admin)
just argocd-deploy  # Deploy ApplicationSet
```

The `argocd-ui` recipe automatically:
1. Looks up the Identity Center user by username
2. Adds the user as ArgoCD admin if not already configured
3. Returns the UI URL

## External Secrets

Sync secrets from AWS Secrets Manager to Kubernetes:

```bash
just secrets-deploy # Install ESO + ClusterSecretStore
just secrets-test   # Verify secret sync
```

## Drupal

```bash
just drupal-setup   # DDEV + FrankenPHP + recipes
just drupal-test    # Search performance tests
```

## Environment

Recommended: [Project Bluefin](https://projectbluefin.io/), [Debian on WSL2](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux), or the included [devcontainer](.devcontainer/).

### macOS (Apple Silicon)

```bash
brew install colima docker devpod
softwareupdate --install-rosetta --agree-to-license
colima start --cpu 4 --memory 12 --vz-rosetta
```

## Justfile Patterns

This repo uses [just](https://github.com/casey/just) with these conventions:

```just
set dotenv-load                    # Load .env
set shell := ["bash", "-lc"]       # Login shell for mise

default:                           # MUST be first recipe
  @just --list

# --- SECTION NAME ---

# Lazy AWS helper (only runs when called)
_account:
  @aws sts get-caller-identity | jq -r '.Account'

# Use as: $(just _account)
[group('eks')]
some-recipe:
  echo "Account: $(just _account)"
```

Key patterns:
- **Lazy helpers**: `_account`, `_bucket`, `_username` - avoids slow startup
- **jq everywhere**: `| jq -r '.field'` instead of `--query`/`sed`
- **Groups**: `[group('eks')]` organizes `just --list` output
- **Section dividers**: `# --- NAME ---` for visual separation
- **Private recipes**: `_` prefix hides from listing
