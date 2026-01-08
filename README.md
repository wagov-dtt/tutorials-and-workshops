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
| Local K8s cluster | `just deploy-local` | No |
| Analytics demo | `just ducklake-test` | No |
| S3 filesystem mount | `just rclone-test` | No |
| Local Drupal CMS | `just drupal-setup` | No |
| AWS EKS cluster | `just setup-eks` | Yes |
| S3 backup demo | `just s3-test` | Yes |
| GitOps with ArgoCD | `just argocd-ui` | Yes |

Run `just` to see all available commands.

## Examples

| Directory | What it teaches | Difficulty |
|-----------|-----------------|------------|
| [kustomize/](kustomize/) | Base K8s manifests, overlays pattern | ⭐ Beginner |
| [ducklake/](ducklake/) | DuckDB analytics with S3 storage | ⭐ Beginner |
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
just ducklake-test  # DuckLake analytics demo
just rclone-test    # S3 filesystem mount demo
just drupal-setup   # Drupal CMS
```

## AWS Examples

**Cost warning**: EKS clusters cost ~$80-100/month. Always destroy when done!

```bash
just setup-eks      # Create EKS cluster (~15 min)
just deploy         # Deploy base manifests
just s3-test        # S3 Pod Identity demo
just secrets-deploy # External Secrets demo
just argocd-ui      # ArgoCD UI URL
just destroy-eks    # IMPORTANT: Destroy when done!
```

## Goose AI Agent

Run [Goose](https://block.github.io/goose/) with Claude models on Amazon Bedrock via LiteLLM proxy. Goose is part of the [Agentic AI Foundation](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation) under the Linux Foundation.

```bash
# 1. Enable Bedrock model access (AWS Console → Bedrock → Model access)
# 2. Configure AWS credentials
aws configure sso && aws sso login

# 3. Run Goose in this project
just goose                                                                     # Claude Sonnet (default)
BEDROCK_MODEL=global.anthropic.claude-opus-4-5-20251101-v1:0 just goose       # Claude Opus
BEDROCK_MODEL=global.anthropic.claude-haiku-4-5-20251001-v1:0 just goose      # Claude Haiku

# 4. Run Goose in another project
DIR=/path/to/project just goose                                                # Change working directory
DIR=~/myapp just goose                                                         # Use any absolute path

# 5. Advanced usage
just goose --help                                                              # Show all options
just goose session start --profile custom                                      # Custom session
just goose session list                                                        # View past sessions
just goose session resume <id>                                                 # Continue session
```

**How it works**: LiteLLM runs as a background proxy translating OpenAI API calls to Bedrock. Goose connects via environment variables configured in the justfile. Includes `developer`, `computercontroller`, and `chatrecall` extensions for code editing, automation, and conversation memory.

**Cost**: ~$0.03-0.75/session with Sonnet. See [Bedrock pricing](https://aws.amazon.com/bedrock/pricing/).

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
| [AGENTS.md](AGENTS.md) | For AI agents and contributors |

Each example directory has its own README with detailed explanations.

## Links

- [DevSecOps Induction](https://soc.cyber.wa.gov.au/training/devsecops-induction/) - Structured training course
- [Just command runner](https://github.com/casey/just) - How the justfile works
- [Kustomize docs](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/) - Base/overlay pattern

## License

[MIT](LICENSE)
