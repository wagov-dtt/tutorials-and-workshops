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
just secrets/secrets-deploy
just secrets/secrets-test
```

Cleanup:

```bash
just secrets/secrets-cleanup
```

## What to Study

| Path | Purpose |
|------|---------|
| `../charts/secrets-demo/templates/clustersecretstore.yaml` | AWS Secrets Manager backend config |
| `../charts/secrets-demo/templates/externalsecret.yaml` | Syncs one AWS secret into Kubernetes |
| `justfile` | Installs ESO with Helm, then installs this repo's demo chart |

## Notes

This demo still uses `ClusterSecretStore` to match the existing EKS Pod Identity setup. For app-specific production use, prefer a namespace-scoped `SecretStore` where practical.
