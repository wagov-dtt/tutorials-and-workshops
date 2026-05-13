# Contributing

This repo contains concise, self-contained DevOps and Kubernetes examples.

## Current Architecture

- Local Kubernetes uses **kind**.
- Kubernetes examples are packaged as **Helm charts** under `charts/`.
- Local app stacks use **Linkerd** by default for mesh identity and authorization.
- Browser-facing stacks use **Traefik static config** rather than ingress/controller-specific CRDs.
- ArgoCD is not modeled in-repo; deploy the Helm charts from CI or an orchestration cluster.

## Principles

- Every example has a `just` recipe—run `just` to list commands.
- Keep examples minimal and document why decisions were made.
- Validate charts with `helm lint` and `helm template` before committing.
- Test local Kubernetes examples with kind via `just validate-local`.
- Prefer simple, explicit Helm templates over helper-heavy chart frameworks.

## Structure

| Directory | Purpose |
|-----------|---------|
| `charts/` | Helm charts for Kubernetes examples |
| `databases/`, `collaboration-stack/`, `rclone/` | Local kind wrappers/docs/recipes |
| `s3-pod-identity/`, `secrets/` | AWS/EKS Helm chart demos |
| `eksauto/` | EKS Terraform configuration |
| `drupal-hugo/` | Drupal DDEV example |
| `justfile`, `shared.just` | Entry point and shared helpers |

## Justfile Patterns

Use shared helpers from `shared.just`:

- `_kind` creates/uses the local kind cluster.
- `_linkerd` installs/checks Linkerd.
- `_platform` means kind + Linkerd are ready.

Local app-stack recipes should generally look like:

```just
deploy: _platform
    kubectl create namespace example --dry-run=client -o yaml | kubectl apply -f -
    kubectl annotate namespace example linkerd.io/inject=enabled config.linkerd.io/default-inbound-policy=deny --overwrite
    helm upgrade --install example ../charts/example -n example
```

## Validation

```bash
just lint
just validate-local
```
