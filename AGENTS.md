# AGENTS.md

This repo is a collection of concise, self-contained examples for tricky DevOps/K8s activities. Examples here are referenced from other projects.

## Principles
- Every example has a `just` recipe - run `just --choose` to explore
- Keep examples minimal and document *why* decisions were made (not just how)
- Use `kubectl kustomize <dir>` to validate manifests before committing
- Test locally if needed with `just deploy-local` (k3d) before EKS
- **Agent workflow**: Edit manifests/recipes, then human runs `just` commands (agent should not run just recipes directly)

## Structure
- `kustomize-*/` - K8s examples with base/overlays pattern
- `justfile` - All recipes, the entry point for everything

## Justfile Patterns
- `set dotenv-load` - Loads `.env` file (AWS_PROFILE, AWS_REGION)
- `set export` - All just variables exported as env vars to recipes
- Define derived vars at top: `ACCOUNT := \`aws sts get-caller-identity ...\``
- Use `{{VAR}}` in recipes for just variables, `$VAR` for env vars
- Use `-` prefix to ignore errors (cleaner than `|| true`)
- Use `envsubst` for templating manifests with `${VAR}` placeholders
- Each command on its own line (avoid `&&` chains)
- Private recipes prefixed with `_` (e.g., `_s3-deploy`)

## EKS Auto Mode Notes
- Pod Identity Agent is built-in - no addon needed
- Use `eksctl create podidentityassociation` to link SA → IAM role
- Pods must be restarted after association created to pick up credentials
- CSI drivers need their own Pod Identity association (separate namespace/SA)
