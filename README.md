# tutorials-and-workshops

Hands-on DevOps and Kubernetes examples. Learn by doing.

## Start Here

**New to this?** Read [GETTING_STARTED.md](GETTING_STARTED.md) first.

```bash
# Install tools and run your first example
just prereqs
just deploy-local
```

This creates a local Kubernetes cluster with databases. No cloud account needed.

## Quick Reference

| What you want | Command | Cloud needed? |
|---------------|---------|---------------|
| AI assistant (`oy`) | `oy "review this repo and suggest simplifications"` | Yes (provider creds) |
| Code audit (`ISSUES.md`) | `oy audit` | Yes (provider creds) |
| Local K8s cluster | `just deploy-local` | No |
| S3 filesystem mount | `just rclone-test` | No |
| Local Drupal CMS | `just drupal-setup` | No |
| AWS EKS cluster | `just setup-eks` | Yes |
| S3 backup demo | `just s3-test` | Yes |
| GitOps with ArgoCD | `just argocd-ui` | Yes (+ Identity Center) |

Run `just` to see all available commands.

## Examples

| Directory | What it teaches | Difficulty |
|-----------|-----------------|------------|
| [kustomize/](kustomize/) | Base K8s manifests, overlays pattern | ⭐ Beginner |
| [rclone/](rclone/) | Mount S3 as filesystem (CSI driver) | ⭐⭐ Intermediate |
| [drupal/](drupal/) | PHP development with DDEV | ⭐⭐ Intermediate |
| [s3-pod-identity/](s3-pod-identity/) | EKS Pod Identity, MySQL backups | ⭐⭐⭐ Advanced |
| [secrets/](secrets/) | External Secrets with AWS Secrets Manager | ⭐⭐⭐ Advanced |
| [argocd/](argocd/) | GitOps with ArgoCD | ⭐⭐⭐ Advanced |
| [eksauto/](eksauto/) | EKS cluster via Terraform | ⭐⭐⭐ Advanced |

See [LEARNING_PATH.md](LEARNING_PATH.md) for the recommended order.

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [mise](https://mise.jdx.dev/) | Tool version manager | `curl https://mise.run \| sh` |
| [Docker](https://docs.docker.com/get-docker/) | Container runtime | Docker Desktop or `docker.io` |

Everything else is installed automatically by `just prereqs`.

## Local Development (No Cloud)

```bash
just deploy-local   # K8s cluster with databases
just rclone-test    # S3 filesystem mount demo
just drupal-setup   # Drupal CMS
```

## AWS Examples

**Cost warning**: EKS clusters cost money—see [eksauto/](eksauto/) for details. Always destroy when done!

```bash
just setup-eks      # Create EKS cluster (~15 min)
just deploy         # Deploy base manifests
just s3-test        # S3 Pod Identity demo
just secrets-deploy # External Secrets demo
just destroy-eks    # IMPORTANT: Destroy when done!
```

## Oy AI Assistant

`just prereqs` installs [`oy-cli`](https://pypi.org/project/oy-cli/) via `mise`, so you can use `oy` directly:

```bash
oy "review this repo and suggest simplifications"
cd ~/myproject && oy "fix the failing tests"
```

`oy` works well with existing provider auth, including AWS Bedrock via your configured AWS profile and region.

If you want `oy` outside this repo, install it from PyPI:

```bash
uv tool install oy-cli   # preferred
# or: pip install oy-cli
```

## Code Auditing

Run `oy audit` in the repo you want to inspect:

```bash
cd ~/myproject
oy audit
oy audit "focus on authentication"
```

This creates or refreshes `ISSUES.md` with prioritised findings based on OWASP ASVS and grugbrain.dev.

`oy audit` works nicely with existing provider auth, including AWS Bedrock credentials from your current AWS profile and region.

## Validation

```bash
just lint           # Validate manifests (kustomize + terraform + trivy)
just validate-local # Run all local tests
```

## Environment Setup

**Recommended**: [Debian on WSL2](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux), [Project Bluefin](https://projectbluefin.io/), or the included [devcontainer](.devcontainer/).

**macOS (Apple Silicon)**:
```bash
brew install colima docker
softwareupdate --install-rosetta --agree-to-license
colima start --cpu 4 --memory 12 --vz-rosetta
```

## Documentation

| Document | Purpose |
|----------|---------|
| [GETTING_STARTED.md](GETTING_STARTED.md) | First-time setup, beginner concepts |
| [LEARNING_PATH.md](LEARNING_PATH.md) | Suggested order for examples |
| [GLOSSARY.md](GLOSSARY.md) | Definitions of key terms |

Each example directory has its own README with detailed explanations.

## Links

- [oy-cli](https://pypi.org/project/oy-cli/) - Small standalone CLI for coding help and `oy audit`
- [DevSecOps Induction](https://soc.cyber.wa.gov.au/training/devsecops-induction/) - Structured training course
- [Just command runner](https://github.com/casey/just) - How the justfile works
- [Kustomize docs](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/) - Base/overlay pattern

## License

[MIT](LICENSE)
