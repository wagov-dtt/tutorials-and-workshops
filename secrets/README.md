# secrets/

> External Secrets Operator with AWS Secrets Manager. Keep secrets out of git entirely.

## Why External Secrets Operator?

Secrets don't belong in git, but Kubernetes Secrets need to exist in the cluster. External Secrets Operator bridges this gap:

1. **Secrets stay in Secrets Manager**: Single source of truth with proper access controls and audit logging
2. **Auto-sync to Kubernetes**: ESO creates and updates K8s Secrets from external sources
3. **Rotation works**: Update a secret in AWS, and ESO syncs it (configurable interval)
4. **No credentials in cluster**: Uses Pod Identity—no AWS keys stored anywhere

**Why not Sealed Secrets?** Sealed Secrets encrypt secrets for git storage. This works, but:
- You still commit encrypted blobs to git
- Rotation requires re-sealing and committing
- Key management adds complexity

ESO keeps secrets out of git entirely. Secrets Manager handles encryption, rotation, and access control.

## Quick Start

```bash
just secrets-deploy   # Install ESO and create example secret
just secrets-test     # Verify secret sync works
```

## Prerequisites

1. EKS cluster with Pod Identity (`just setup-eks`)
2. Secret in AWS Secrets Manager (created by Terraform)

## What Gets Deployed

| Resource | Purpose |
|----------|---------|
| external-secrets namespace | ESO components |
| External Secrets Operator | Controller (via Helm) |
| ClusterSecretStore | Configures AWS Secrets Manager as backend |
| ExternalSecret | Example that syncs `training/db-credentials` |

## How It Works

```
AWS Secrets Manager          External Secrets Operator          Kubernetes
┌─────────────────┐         ┌──────────────────────┐          ┌──────────┐
│ training/       │  sync   │ ExternalSecret       │  creates │ Secret   │
│ db-credentials  │ ──────► │ (references secret)  │ ───────► │ db-creds │
└─────────────────┘         └──────────────────────┘          └──────────┘
        │                            │
        │                            │ uses
        │                   ┌────────┴────────┐
        │                   │ ClusterSecretStore │
        │                   │ (AWS SM backend)   │
        │                   └────────┬────────┘
        │                            │ Pod Identity
        └────────────────────────────┘
```

## Directory Structure

```
secrets/
├── base/
│   ├── namespace.yaml           # external-secrets namespace
│   ├── clustersecretstore.yaml  # AWS Secrets Manager config
│   └── externalsecret.yaml      # Example secret reference
└── kustomization.yaml
```

## Learning Goals

- **Zero secrets in git**: ExternalSecret references a path, not the actual value
- **Pod Identity for ESO**: The operator uses an IAM role with no credentials stored
- **ClusterSecretStore vs SecretStore**: Cluster-wide vs namespace-scoped backends
- **Sync behavior**: Refresh interval, error handling, and secret templates

## Creating Secrets in AWS

```bash
# Create a secret (JSON format)
aws secretsmanager create-secret \
  --name training/db-credentials \
  --secret-string '{"username":"admin","password":"changeme"}'

# Update existing secret
aws secretsmanager put-secret-value \
  --secret-id training/db-credentials \
  --secret-string '{"username":"admin","password":"newpassword"}'
```

ESO syncs changes within the refresh interval (default: 1 hour, configured to 5 minutes in this example).

## See Also

- [LEARNING_PATH.md](../LEARNING_PATH.md#23-external-secrets) - Step-by-step walkthrough
- [GLOSSARY.md](../GLOSSARY.md) - Definitions (Secrets Manager, Pod Identity)
- [eksauto/](../eksauto/) - Terraform that creates the IAM role and secret
- [External Secrets Operator docs](https://external-secrets.io/) - Official ESO documentation
