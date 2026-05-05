---
title: "Getting Started"
description: "First-time setup, local Kubernetes, and secure delivery habits for the tutorials."
weight: 1
icon: "rocket"
---

New to DevOps or Kubernetes? Start here. The goal is not to finish every tutorial; it is to produce evidence that you can deliver, secure, and operate a small cloud-native workload.

**Evidence beats course completion.** For each section, produce one artefact: a pull request, diagram, runbook, threat model, test, or short demo.

## What You'll Learn

This repo teaches modern infrastructure patterns through hands-on examples:

- **Kubernetes basics**: Deploying apps, databases, and services.
- **Kustomize**: Managing configuration without templating.
- **S3 and cloud storage**: Backups, mounts, and object storage.
- **GitOps**: Automated deployments with ArgoCD.
- **Infrastructure as Code**: Creating cloud resources with Terraform.
- **Secure delivery**: Trust boundaries, validation, least privilege, and reviewable automation.

See [GLOSSARY.md](glossary.md) for definitions of these terms.

## Operating Rules

| Rule | What good looks like |
|------|----------------------|
| Learn by doing | Run the local labs before the AWS labs. Explain the commands, manifests, and failure modes. |
| Keep work reproducible | Source-controlled config, repeatable `just` recipes, pinned tools via `mise`, and no undocumented console changes. |
| Validate early | Run format, tests, Trivy/IaC checks, and focused security review before merge or deploy. |
| Keep humans accountable | Automation and AI can assist, but people approve consequential changes. |

## Prerequisites

You need these installed:

| Tool | What it does | Install |
|------|--------------|---------|
| [mise](https://mise.jdx.dev/) | Manages tool versions | `curl https://mise.run \| sh` |
| [Docker](https://docs.docker.com/get-docker/) | Runs containers | Follow Docker docs |

Everything else, including kubectl, k3d, Helm, Terraform, Hugo, and Sass, is installed through `mise`.

## Your First Commands

```bash
# Clone the repo
git clone https://github.com/wagov-dtt/tutorials-and-workshops
cd tutorials-and-workshops

# Install all tools
just prereqs

# Create a local Kubernetes cluster and deploy databases
just deploy-local
```

**Success looks like:**

```text
INFO[0000] Creating cluster 'tutorials'
INFO[0003] Cluster 'tutorials' created successfully!
namespace/databases created
deployment.apps/postgres created
...
```

This creates a local [k3d](https://k3d.io/) cluster with PostgreSQL, MySQL, MongoDB, and Elasticsearch running in Docker.

## Explore What You Built

```bash
# See all running pods
kubectl get pods -A

# Open k9s, a terminal UI for Kubernetes
k9s
```

In k9s: press `0` to see all namespaces, arrow keys to navigate, `d` to describe a pod, `l` for logs, and `q` to quit.

## What Just Happened?

1. `just prereqs` installed kubectl, k3d, Helm, and other tools via `mise`.
2. `just deploy-local` created a k3d cluster called `tutorials`.
3. Kubernetes manifests from `kustomize/` were applied to deploy databases.

The configuration lives in `kustomize/overlays/local/kustomization.yaml`. It combines base manifests with local-specific settings.

## ADR-Aligned Delivery Checklist

The repository examples are intentionally small, but the habits should match DTT architecture decisions.

| Area | ADR expectation | Practice in this repo |
|------|-----------------|-----------------------|
| Configuration management | [ADR 010](https://adr.dtt.digital.wa.gov.au/operations/010-configmgmt.html): infrastructure is reproducible from Git; validate with Trivy plus `terraform plan` or `kubectl diff`; use tagged releases for higher environments. | Study `kustomize/`, `eksauto/terraform/`, and `just lint`. Avoid manual drift; prefer a reviewed manifest, plan, or recipe change. |
| CI/CD | [ADR 004](https://adr.dtt.digital.wa.gov.au/development/004-cicd.html): build, test, scan, analyse, release; keep unprivileged CI in GitHub Actions; run AWS-privileged deployment from controlled operations runners with assumed roles. | This site uses GitHub Actions only for unprivileged static publishing. Treat AWS examples as local/controlled operations work unless a runner and role boundary are explicitly approved. |
| Workloads | [ADR 002](https://adr.dtt.digital.wa.gov.au/operations/002-workloads.html): use CNCF-certified Kubernetes; prefer AWS EKS Auto Mode for cloud workloads; keep durable state in managed services where practical. | Learn locally with k3d, then compare with `eksauto/`. Note where demo databases use cluster storage and where production would use managed database, object, or shared file services. |
| AI governance | [ADR 011](https://adr.dtt.digital.wa.gov.au/security/011-ai-governance.html): start with low-risk, non-sensitive tasks; set explicit workspace/tool/model boundaries; require human approval for production, release, customer, or high-impact actions. | Use `oy` for repository explanation, coding help, and audits. Do not give AI broad credentials, sensitive data, or autonomous deploy authority. Keep prompts, outputs, tool calls, and approvals reviewable. |

## Optional: Use oy Directly

Install [`oy-cli`](https://crates.io/crates/oy-cli) from crates.io with mise's Cargo backend to use `oy` directly from your shell:

```bash
mise use -g cargo-binstall
mise use -g cargo:oy-cli
oy "summarise this repo and suggest next steps"
oy audit
```

`oy audit` creates or refreshes `ISSUES.md`. It works with existing provider auth, including AWS Bedrock via your configured AWS profile and region.

## Hands-On Path

### Beginner Path, no AWS required

| Order | Command | What you learn |
|-------|---------|----------------|
| 1 | `just deploy-local` | Kubernetes basics, Kustomize |
| 2 | `just rclone-test` | Mounting cloud storage as filesystems |
| 3 | `just drupal-setup` | Local PHP development with DDEV |

### Intermediate Path, requires AWS

After you're comfortable with local examples:

| Order | Command | What you learn |
|-------|---------|----------------|
| 1 | `just setup-eks` | Terraform, EKS Auto Mode |
| 2 | `just s3-test` | Pod Identity, IAM roles |
| 3 | `just secrets-deploy` | External Secrets Operator |

**Cost warning**: EKS clusters cost money. See [eksauto/](examples/eksauto.md) for details and always run `just destroy-eks` when done.

For detailed walkthroughs of each example, continue with [LEARNING_PATH.md](learning-path.md).

## Core Skills to Build

| Skill | Learn | Prove it |
|------|-------|----------|
| Git and review | Branches, commits, pull requests, small changes. | Open a small documentation or manifest PR. |
| Local tooling | `mise`, `just`, Docker, k3d, kubectl, k9s. | Run `just prereqs`, `just deploy-local`, and inspect pods. |
| Kubernetes config | Namespaces, Deployments, Services, PVCs, Kustomize overlays. | Explain `kubectl kustomize kustomize/overlays/local`. |
| Infrastructure as Code | Terraform plan/apply/destroy, state, drift, tagging. | Read `eksauto/terraform` and run `terraform fmt -check`. |
| Secure delivery | Trust boundaries, validation, least privilege, audit evidence. | Add one focused test or scan for a change. |

## Key Concepts

### What is Just?

[Just](https://github.com/casey/just) is a command runner. The `justfile` contains all recipes:

```bash
just              # List all recipes
just deploy-local # Run a specific recipe
```

## Baseline Commands

```bash
just lint       # local validation, including docs build
oy audit        # AI-assisted review; keep outputs human-reviewed
```

When adding a security control, name the trust boundary, validate near that boundary, fail closed, and add a focused test.

## Troubleshooting

### "command not found: kubectl"

Run `just prereqs` to install tools, then restart your shell or run `source ~/.bashrc`.

### "Cannot connect to the Docker daemon"

Start Docker Desktop, or on Linux: `sudo systemctl start docker`.

### k3d cluster won't start

```bash
k3d cluster delete tutorials
just deploy-local
```

### Pods stuck in "Pending"

Usually waiting for resources. Check events:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

### "Drupal site won't load"

```bash
cd drupal
ddev status       # Check if running
ddev start        # Start if stopped
ddev logs -s web  # View errors
```

## Getting Help

- Run `just` to list all available commands with descriptions.
- Each directory has a README.md explaining that example.
- See [GLOSSARY.md](glossary.md) and [LEARNING_PATH.md](learning-path.md) for reference.

## Cleanup

```bash
# Stop local cluster, preserving data
k3d cluster stop tutorials

# Delete local cluster completely
k3d cluster delete tutorials

# Stop Drupal, using DDEV directly
cd drupal && ddev stop
```

## Optional Learning Resources

Keep optional resources purposeful:

- [GitHub learning resources](https://docs.github.com/en/get-started/start-your-journey/git-and-github-learning-resources)
- [Kubernetes basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Terraform language](https://developer.hashicorp.com/terraform/language)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [ACSC ISM](https://www.cyber.gov.au/resources-business-and-government/essential-cyber-security/ism)
- [SANS SEC540](https://www.sans.org/cyber-security-courses/cloud-security-devops-automation/) for cloud security and DevSecOps depth.
- [SANS SEC522](https://www.sans.org/cyber-security-courses/application-security-securing-web-apps-api-microservices/) for web/API security.
- [CKA, CKAD, or CKS](https://training.linuxfoundation.org/certification/) when Kubernetes certification is useful evidence.

## See Also

- [LEARNING_PATH.md](learning-path.md) - Detailed walkthrough of each example.
- [GLOSSARY.md](glossary.md) - Definitions of key terms.
- [kustomize/](examples/kustomize.md) - The base manifests deployed by `just deploy-local`.
