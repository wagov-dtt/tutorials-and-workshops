---
title: "Contributing"
description: "Repository conventions, justfile patterns, and validation checks."
weight: 40
icon: "handshake"
---

This repo contains concise, self-contained examples for DevOps and Kubernetes workflows. Examples here are referenced from other projects.

**Note**: This is a training/examples repo. Local `just` recipes are the source of truth for validation. GitHub Actions should call the same commands rather than duplicate project logic.

## Philosophy: Grug-Brained Development

This repo follows ["grug-brained"](https://grugbrain.dev) principles. The goal is working software, not architectural purity.

1. **Complexity is the Enemy**
   - Complexity is cognitive debt. Always choose simpler over "correct."
   - If a solution feels clever, it's probably wrong.

2. **Locality of Behavior (LoB) is King**
   - Behavior should be obvious by looking at a single unit of code.
   - Don't split logic across files for "Separation of Concerns."
   - Co-locate everything: HTML directives inline, styles via utility classes.

3. **WET > DRY**
   - A little duplication beats a bad abstraction.
   - Only abstract with 3+ identical cases AND an obvious pattern.

4. **Testing: Behavior Over Implementation**
   - E2E/integration tests are more valuable than unit tests.
   - Test what users see, not internal details.

5. **Boring Tech Wins**
   - Use battle-tested tools. Avoid shiny new things.
   - Factor code, not infrastructure.

## Principles

- Every example has a `just` recipe—run `just` to list all available commands
- Keep examples minimal and document *why* decisions were made (not just how)
- Use `kubectl kustomize <dir>` to validate manifests before committing
- Test locally with `just deploy-local` (k3d) before deploying to EKS

## Structure

| Directory | Purpose |
|-----------|---------|
| `argocd/`, `apps-sso/`, `rclone/`, `s3-pod-identity/`, `secrets/` | Kubernetes examples |
| `kustomize/` | Shared base manifests |
| `eksauto/` | EKS Terraform configuration |
| `drupal/` | Drupal DDEV example |
| `justfile` | All recipes—the entry point for everything |

## Justfile Patterns

### Structure

```just
set dotenv-load                    # Load .env (AWS_PROFILE, AWS_REGION)
set export                         # Export vars to recipes
set shell := ["bash", "-lc"]       # Login shell for mise/asdf

default:                           # MUST be first recipe
  @just --list

# --- SECTION NAME ---

[group('section')]                 # Groups in --list output
recipe-name PARAM="default":       # Public recipes
  command

_private-helper:                   # Private (hidden from --list)
  command
```

### Lazy AWS Helpers

Avoid top-level backtick variables (slow startup). Use private recipes called on-demand:

```just
# Define once
_account:
  @aws sts get-caller-identity | jq -r '.Account'

# Use as: $(just _account)
some-recipe:
  echo "Account: $(just _account)"
```

### Conventions

- **jq everywhere**: Use `| jq -r '.field'` instead of `--query`/`--output text`/`sed`
- **Groups**: `[group('eks')]` organizes `just --list` output
- **Working directory**: `[working-directory: 'path']` for context-specific recipes
- **Ignore errors**: `-` prefix (e.g., `-kubectl delete ...`)
- **Quiet output**: `@` prefix hides command echo
- **Multi-line scripts**: Use `#!/usr/bin/env bash` shebang for complex logic
- **No `&&` chains**: One command per line for readability
- **Section dividers**: Use `# --- SECTION NAME ---` between logical groups
- **Environment variables**: Define as constants at top (e.g., `default_cluster := "training01"`)
- **Background processes**: Use `&` for background + `pkill -f <port>` for cleanup

## EKS Auto Mode Notes

- Cluster is managed by Terraform in `eksauto/terraform/`
- Pod Identity associations are pre-created by Terraform for s3-test, kube-system EFS CSI, and external-secrets namespaces
- Use `just setup-eks` to create, `just destroy-eks` to tear down
- Pods must be restarted after association creation to pick up credentials
- CSI drivers need their own Pod Identity association (separate namespace/SA)
- On EKS, POSIX-style S3 mounts use AWS S3 Files through the EFS CSI driver (`s3files-s3` StorageClass)
- Keep veloxpack rclone CSI limited to local k3d/dev examples (`rclone/`, `just rclone-test`, Drupal k3d)

## Quality Checks

Run the cheapest relevant checks before committing:

```bash
just --list
just --dry-run s3-test
just --dry-run s3-restore
just --dry-run --yes validate-aws
terraform -chdir=eksauto/terraform fmt -check -diff
AWS_PROFILE=<profile> AWS_REGION=<region> terraform -chdir=eksauto/terraform validate
```

For S3 Files changes, also render the manifest with explicit substitutions:

```bash
export AWS_REGION=us-east-1 S3FILES_FILE_SYSTEM_ID=fs-12345678
kubectl kustomize s3-pod-identity | envsubst '$AWS_REGION $S3FILES_FILE_SYSTEM_ID' >/tmp/s3-pod-identity.yaml
grep -E 'provisioner:|fileSystemId:|storageClassName:|rclone.csi.veloxpack.io' /tmp/s3-pod-identity.yaml
```

Expected: `provisioner: efs.csi.aws.com`, `fileSystemId` substituted, PVCs use `storageClassName: s3files-s3`, and no `rclone.csi.veloxpack.io` in EKS manifests.

## See Also

- [Overview](overview.md) - Project overview and quick start
- [GLOSSARY.md](glossary.md) - Definitions of key terms
- [LEARNING_PATH.md](learning-path.md) - Suggested order for examples
