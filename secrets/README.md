# secrets/

> External Secrets Operator demo packaged as `charts/secrets-demo`.

## Security Hierarchy: Local > Global

Prefer smaller secret blast radius:

| Approach | Blast Radius | Use Case |
|----------|--------------|----------|
| Ephemeral fetch | None | One-time ops |
| Kubernetes Secret | Single namespace | App runtime |
| External Secrets Operator | Namespace, synced from AWS | Existing AWS secret bridge |
| AWS Secrets Manager directly | AWS account | Admin/CI operations |

## Quick Start

Requires EKS and AWS credentials:

```bash
just secrets/deploy
just secrets/smoke
```

Cleanup:

```bash
just secrets/clean
```

## What to Study

| Path | Purpose |
|------|---------|
| `../charts/secrets-demo/templates/clustersecretstore.yaml` | AWS Secrets Manager backend config; defaults to namespace-scoped `SecretStore` |
| `../charts/secrets-demo/templates/externalsecret.yaml` | Syncs one AWS secret into Kubernetes |
| `justfile` | Installs ESO with Helm, then installs this repo's demo chart |

## Notes

This demo defaults to a namespace-scoped `SecretStore` to keep blast radius local. Set `secretStore.kind=ClusterSecretStore` only when the lesson explicitly needs one cluster-wide store.
