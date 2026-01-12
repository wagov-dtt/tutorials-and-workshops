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
| AI agent (Goose + Bedrock) | `just configure-goose` + `just litellm` | Yes (Bedrock) |
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

Run [Goose](https://block.github.io/goose/) with AWS Bedrock models via LiteLLM proxy.

### Quick Start

```bash
# 1. Enable Bedrock model access (AWS Console → Bedrock → Model access)
# 2. Configure AWS credentials
aws configure sso && aws sso login

# 3. Install Goose config (one-time setup)
just configure-goose

# 4. Start LiteLLM proxy in one terminal
just litellm

# 5. Run Goose in another terminal
goose session
```

### How It Works

1. **LiteLLM proxy** (`just litellm`) runs on `localhost:54000`, translating OpenAI API calls to AWS Bedrock
2. **Goose config** (`goose-config.yaml`) configures Goose to use the proxy with `claude-sonnet-4-5` as default
3. **Extensions enabled**: developer, chatrecall, extensionmanager, todo, skills, computercontroller

### Available Models

Configured in [`litellm_goose.yaml`](litellm_goose.yaml) - 4 models using global INFERENCE_PROFILE endpoints:

| Model Name | Description | Input/Output Cost |
|------------|-------------|-------------------|
| `claude-sonnet-4-5` | Default - best for coding | $3.00 / $15.00 per M tokens |
| `claude-opus-4-5` | Most capable - complex reasoning | $15.00 / $75.00 per M tokens |
| `amazon-nova-2-lite` | Fastest - NEW Nov 2025 | $0.06 / $0.24 per M tokens |
| `claude-haiku-4-5` | Fast - quick edits | $0.80 / $4.00 per M tokens |

**Switch models** in Goose: Type `/config` in session, then change `GOOSE_MODEL` value (e.g., `claude-haiku-4-5`)

**Cost estimate**: ~$0.03-0.75/session with Sonnet (10-50K tokens)

### Use in Other Projects

Refer to [`litellm_goose.yaml`](litellm_goose.yaml) and [`goose-config.yaml`](goose-config.yaml) to setup other projects or dev environments.

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

- [Goose AI](https://block.github.io/goose/) - Agentic AI assistant ([Agentic AI Foundation](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation) under Linux Foundation)
- [DevSecOps Induction](https://soc.cyber.wa.gov.au/training/devsecops-induction/) - Structured training course
- [Just command runner](https://github.com/casey/just) - How the justfile works
- [Kustomize docs](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/) - Base/overlay pattern

## License

[MIT](LICENSE)
