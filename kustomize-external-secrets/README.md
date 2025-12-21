# kustomize-external-secrets/

External Secrets Operator with AWS Secrets Manager.

## Why External Secrets Operator?

**Secrets don't belong in git.** But K8s Secrets need to exist in the cluster. External Secrets Operator bridges this gap:

1. **Secrets stay in Secrets Manager**: Single source of truth, proper access controls, audit logging
2. **Auto-sync to K8s**: ESO creates/updates K8s Secrets from external sources
3. **Rotation works**: Update secret in AWS, ESO syncs it (configurable interval)
4. **No credentials in cluster**: Uses Pod Identity - no AWS keys stored anywhere

**Why not Sealed Secrets?** Sealed Secrets encrypt secrets for git storage. Works, but:
- Still commits encrypted blobs to git
- Rotation requires re-sealing and committing
- Key management complexity

ESO keeps secrets out of git entirely. Secrets Manager handles encryption, rotation, access control.

## Quick Start

```bash
just external-secrets-deploy   # Install ESO + create example secret
just external-secrets-test     # Verify secret sync works
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
kustomize-external-secrets/
├── base/
│   ├── namespace.yaml         # external-secrets namespace
│   ├── clustersecretstore.yaml # AWS Secrets Manager config
│   └── externalsecret.yaml    # Example secret reference
└── kustomization.yaml
```

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

ESO syncs changes within the refresh interval (default: 1 hour, our config: 5 minutes).

## Learning Goals

- **Zero secrets in git**: ExternalSecret references a path, not the value
- **Pod Identity for ESO**: Operator uses IAM role, no credentials stored
- **ClusterSecretStore vs SecretStore**: Cluster-wide vs namespace-scoped
- **Sync behavior**: Refresh interval, error handling, secret templates
