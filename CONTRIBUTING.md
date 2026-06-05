# Contributing

This repo contains concise, self-contained DevOps and Kubernetes training examples. Keep changes easy to inspect, easy to run, and safe by default.

## Architecture rules

- Local Kubernetes uses [kind](https://kind.sigs.k8s.io/).
- Kubernetes examples are packaged as [Helm](https://helm.sh/docs/) charts under `charts/`.
- Local app stacks use [Linkerd](https://linkerd.io/2/) for mesh identity and authorization.
- Browser-facing local stacks use [Traefik file/static config](https://doc.traefik.io/traefik/providers/file/) instead of ingress-controller-specific CRDs.
- ArgoCD manifests are not modeled in-repo. Deploy charts from CI or reconcile them from an orchestration cluster. See [argocd/README.md](argocd/README.md).

## Design principles

- Prefer small examples with explicit data flow.
- Keep each lab runnable through a `just` recipe; run `just` to list commands.
- Document trade-offs near the code that makes them.
- Prefer simple Helm templates over helper-heavy chart frameworks.
- Validate charts with `helm lint` and `helm template` before committing.
- Test local Kubernetes changes with kind via `just validate-local` when practical.
- For cloud labs, fail closed: name the AWS account/region, document cost, and provide cleanup.

## Repository structure

| Path | Purpose |
|------|---------|
| `charts/` | Helm charts for Kubernetes examples |
| `databases/`, `collaboration-stack/`, `rclone/`, `observability/` | Local kind wrappers, docs, and recipes |
| `s3-pod-identity/`, `secrets/` | AWS/EKS Helm chart demos |
| `eksauto/` | EKS Terraform configuration |
| `drupal-hugo/` | Drupal/DDEV example |
| `justfile`, `shared.just` | Entry point and shared helpers |

## Justfile patterns

Use shared helpers from `shared.just`:

- `_kind` creates or reuses the local kind cluster.
- `_linkerd` installs and checks Linkerd.
- `_platform` means kind + Linkerd are ready.

Typical local app-stack recipe:

```just
deploy: _platform
    kubectl create namespace example --dry-run=client -o yaml | kubectl apply -f -
    kubectl annotate namespace example linkerd.io/inject=enabled config.linkerd.io/default-inbound-policy=deny --overwrite
    helm upgrade --install example ../charts/example -n example
```

## Documentation style

- Start with what the reader can run.
- Mark cloud/costing steps clearly.
- Link to official docs for external tools instead of re-explaining them.
- Keep generated/vendor docs out of repo-wide edits: ignore `.terraform/` and `restic/github-dump/`.
- Use tables for command maps and path references.

## Validation

Run the cheapest relevant check first:

```bash
just check
```

Before a broad change, run:

```bash
just lint
```

For local behavior changes, run:

```bash
just validate-local
```

Useful external references:

- [Helm chart best practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Linkerd authorization policy](https://linkerd.io/2/features/policy/)
- [Terraform style conventions](https://developer.hashicorp.com/terraform/language/style)
