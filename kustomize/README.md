# kustomize/

> Core Kubernetes manifests using the base/overlays pattern. This is the foundation for all other examples.

## Why Kustomize?

Kustomize is built into `kubectl`—no extra tooling required. It excels at:

1. **Environment variants**: Same base manifests with different overlays for local/staging/prod
2. **Patching without templating**: Merge patches, JSON patches, strategic merge—no `{{ }}` syntax
3. **Composing multiple sources**: Pull in bases from different directories and layer patches

**When to use Helm instead**: Helm charts are great for third-party software (installing Postgres, ArgoCD, etc.). For your own manifests, Kustomize is often simpler—just YAML, no templating logic, easy to debug with `kubectl kustomize`.

## Quick Start

**Local (k3d)**:
```bash
just deploy-local
```

**EKS**:
```bash
just setup-eks      # Create cluster (uses eksauto/)
just deploy         # Apply training01 overlay
```

## What's Here

| Path | Purpose |
|------|---------|
| `base/` | Namespace and debug pod (whoami) |
| `databases/` | Postgres, MySQL, MongoDB, Elasticsearch (single-node dev instances) |
| `overlays/local/` | k3d deployment configuration |
| `overlays/training01/` | EKS deployment configuration |

## Learning Goals

- **Kustomize base/overlay pattern**: See how `overlays/local/kustomization.yaml` composes `base/`, `databases/`, and `kube-system/`
- **Environment-specific config**: Compare local vs training01 overlays for differences in annotations and storage classes
- **Simple database deployments**: Each database is a single YAML file—minimal, readable, no operators required

## Exploring

After deployment:

```bash
k9s                                            # Browse namespaces and pods
kubectl get pods -A                            # List all pods
kubectl exec -it whoami -n default -- sh       # Debug shell
```

## Files to Study

- `databases/postgres.yaml` - Single-node Postgres with PVC
- `overlays/local/kustomization.yaml` - How overlays compose resources

## See Also

- [LEARNING_PATH.md](../LEARNING_PATH.md#11-deploy-local-databases) - Step-by-step walkthrough
- [GLOSSARY.md](../GLOSSARY.md#kustomize) - Kustomize definition
- [Kustomize documentation](https://kustomize.io/) - Official docs
- [ducklake/](../ducklake/) - Uses these database deployments
