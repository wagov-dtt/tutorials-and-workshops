# kustomize/

Core Kubernetes manifests with base/overlays pattern. This is the foundation used across other examples.

## Why Kustomize?

**Helm for packages, Kustomize for composition.** Kustomize is built into `kubectl` - no extra tooling. It excels at:

1. **Environment variants**: Same base manifests, different overlays for local/staging/prod
2. **Patching without templating**: Merge patches, JSON patches, strategic merge - no `{{ }}` soup
3. **Composing multiple sources**: Pull in bases from different directories, layer patches

**Why not Helm for everything?** Helm charts are great for third-party software (install Postgres, ArgoCD, etc.). For your own manifests, Kustomize is simpler - just YAML, no templating logic, easy to debug with `kubectl kustomize`.

## What's Here

| Path | Purpose |
|------|---------|
| `base/` | Namespace + debug pod (whoami) |
| `databases/` | Postgres, MySQL, MongoDB, Elasticsearch (single-node dev instances) |
| `overlays/local/` | k3d deployment |
| `overlays/training01/` | EKS deployment |

## Quick Start

**Local (k3d):**
```bash
just deploy-local
```

**EKS:**
```bash
just setup-eks      # Create cluster (uses eksauto/)
just deploy         # Apply training01 overlay
```

## Learning Goals

- **Kustomize base/overlay pattern**: See how `overlays/local/kustomization.yaml` composes `base/`, `databases/`, and `kube-system/`
- **Environment-specific config**: Compare local vs training01 overlays for differences (annotations, storage classes)
- **Simple database deployments**: Each database is a single YAML file - minimal, readable, no operators

## Exploring

After deployment:
```bash
k9s                          # Browse namespaces and pods
kubectl get pods -A          # List all pods
kubectl exec -it whoami -n default -- sh  # Debug shell
```

## Files to Study

- `databases/postgres.yaml` - Single-node Postgres with PVC
- `overlays/local/kustomization.yaml` - How overlays compose resources
