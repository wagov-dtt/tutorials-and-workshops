# AGENTS.md

This repo contains concise, self-contained examples for DevOps and Kubernetes workflows. Examples here are referenced from other projects.

**Note**: This is a training/examples repo. Local `just` recipes matter more than CI automation. No GitHub Actions workflows are needed—validation happens locally via `just lint`.

## About AGENTS.md

This file follows the [AGENTS.md standard](http://agents.md/) from OpenAI, now part of the [Agentic AI Foundation (AAIF)](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation) under the Linux Foundation. It provides project-specific guidance for AI coding agents like [Goose](https://block.github.io/goose), Cursor, Copilot, and others.

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
- **Agent workflow**: Agents can run local recipes (k3d, DDEV, `just lint`, `just validate-local`) but should NOT run recipes that use credentials against remote targets (AWS, EKS, terraform apply)

## Structure

| Directory | Purpose |
|-----------|---------|
| `argocd/`, `ducklake/`, `rclone/`, `s3-pod-identity/`, `secrets/` | Kubernetes examples |
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
- Pod Identity associations are pre-created by Terraform for s3-test and veloxpack namespaces
- Use `just setup-eks` to create, `just destroy-eks` to tear down
- Pods must be restarted after association creation to pick up credentials
- CSI drivers need their own Pod Identity association (separate namespace/SA)

## See Also

- [README.md](README.md) - Project overview and quick start
- [GLOSSARY.md](GLOSSARY.md) - Definitions of key terms
- [LEARNING_PATH.md](LEARNING_PATH.md) - Suggested order for examples
