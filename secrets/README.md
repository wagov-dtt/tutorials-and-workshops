# secrets/

External Secrets Operator demo packaged as `charts/secrets-demo`.

This is an AWS/EKS lab. Run `just aws-preflight` first so you know which account and region will be used.

## Security model: local before global

Prefer the smallest secret blast radius that works:

| Approach | Blast radius | Good for |
|----------|--------------|----------|
| Ephemeral fetch | No stored Kubernetes secret | One-time ops |
| Kubernetes Secret | One namespace | App runtime |
| External Secrets Operator + namespace `SecretStore` | One namespace, synced from AWS | Bridging existing AWS secrets into Kubernetes |
| External Secrets Operator + `ClusterSecretStore` | Whole cluster | Explicit platform-level reuse |
| AWS Secrets Manager direct access | AWS account/IAM boundary | Admin and CI operations |

The demo defaults to a namespace-scoped `SecretStore`. Use `ClusterSecretStore` only when the lesson explicitly needs one cluster-wide store.

## Quick start

Prerequisites:

- EKS cluster from `just eksauto/setup-eks`
- AWS credentials/profile configured in `.env` or your shell
- Terraform-created `training/db-credentials` secret

```bash
just secrets/deploy
just secrets/smoke
```

## What to study

| Path | Purpose |
|------|---------|
| `../charts/secrets-demo/templates/clustersecretstore.yaml` | AWS Secrets Manager backend config; defaults to namespace-scoped `SecretStore` |
| `../charts/secrets-demo/templates/externalsecret.yaml` | Syncs one AWS secret into Kubernetes |
| `../charts/secrets-demo/templates/networkpolicy.yaml` | Namespace-scoped network boundary example |
| `justfile` | Installs ESO with Helm, then installs this repo's demo chart |

## Useful commands

```bash
kubectl -n secrets-demo get secretstore,externalsecret,secret
kubectl -n external-secrets logs deploy/external-secrets --tail=100
```

## Cleanup

```bash
just secrets/clean
```

## References

- [External Secrets Operator](https://external-secrets.io/latest/)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
