# secrets/

> Managing secrets in Kubernetes. Prefer local over global.

## Security Hierarchy: Local > Global

When choosing where to store secrets, prefer smaller surfaces:

| Approach | Blast Radius | Use Case |
|----------|--------------|----------|
| Ephemeral (ad-hoc fetch, no storage) | None | One-time ops |
| K8s Secret (namespace-scoped) | Single namespace | Default for app runtime |
| External Secrets Operator | Namespace, but syncs from account-wide | Legacy bridging |
| AWS Secrets Manager (account-wide) | Entire AWS account | Last resort |

**Principle**: Secrets adjacent to their workload minimise attack surface. Account-wide stores increase exposure - any compromised credential in that account can access them.

## Approaches at a Glance

1. **Ad-hoc fetch (no storage)**: Migrations, one-time setup - fetch from AWS, use, discard
2. **K8s Secret (namespace)**: App runtime credentials - scope limited to namespace
3. **ESO**: When you need automatic sync from existing account-wide secrets
4. **Secrets Manager directly**: Never from pods - only for admin/CI operations

## Ad-hoc Operations (Preferred)

For one-time DB operations (creating databases, users), fetch secrets temporarily rather than storing them.

### Template with envsubst

Create `template.sql` with bash variables:

```sql
CREATE DATABASE IF NOT EXISTS `${APP_DB}`;
CREATE USER IF NOT EXISTS '${APP_USR}'@'%' IDENTIFIED BY '${APP_PW}';
GRANT ALL PRIVILEGES ON `${APP_DB}`.* TO '${APP_USR}'@'%';
FLUSH PRIVILEGES;
```

### Secure Execution

HereDoc pattern keeps secrets out of `ps`:

```bash
export APP_DB="mydb"
export APP_USR="myuser"
export APP_PW=$(openssl rand -hex 16)

RDS=$(aws secretsmanager get-secret-value --secret-id "my-rds-secret" \
  --query 'SecretString' --output text)

{
  echo "export MYSQL_PWD='$(echo "$RDS" | jq -r .password)'"
  echo "mysql -h '$(echo "$RDS" | jq -r .host)' -u '$(echo "$RDS" | jq -r .username)' << 'SQL_EOF'"
  envsubst < template.sql
  echo "SQL_EOF"
} | kubectl run sql-job-$RANDOM -i --rm --image=mysql:8.0 --restart=Never -- bash

kubectl create secret generic "${APP_DB}-creds" \
  --from-literal=host="$(echo "$RDS" | jq -r .host)" \
  --from-literal=database="${APP_DB}" \
  --from-literal=username="${APP_USR}" \
  --from-literal=password="${APP_PW}"
```

**Why HereDoc**: `<< 'SQL_EOF'` sends SQL via stdin, so passwords never appear in container's `ps aux`.

## External Secrets Operator (Fallback)

When secrets must live in AWS for organisational reasons, ESO bridges AWS Secrets Manager to Kubernetes. It's useful but not the default - prefer keeping secrets close to workloads.

### Why ESO?

Secrets don't belong in git, but Kubernetes Secrets need to exist in the cluster. ESO bridges this gap:

- **Secrets stay in Secrets Manager**: Single source of truth with audit logging
- **Auto-sync to Kubernetes**: Creates and updates K8s Secrets automatically
- **Rotation works**: Update in AWS, ESO syncs (configurable interval)
- **No AWS keys in cluster**: Uses Pod Identity

**Why not Sealed Secrets?** Sealed Secrets encrypt for git storage, but you still commit encrypted blobs, and rotation requires re-sealing.

### Quick Start

```bash
just secrets-deploy   # Install ESO and create example secret
just secrets-test     # Verify secret sync works
```

### Prerequisites

1. EKS cluster with Pod Identity (`just setup-eks`)
2. Secret in AWS Secrets Manager (created by Terraform)

### What Gets Deployed

| Resource | Purpose |
|----------|---------|
| external-secrets namespace | ESO components |
| External Secrets Operator | Controller (via Helm) |
| ClusterSecretStore | Configures AWS Secrets Manager as backend |
| ExternalSecret | Example that syncs `training/db-credentials` |

### How It Works

AWS Secrets Manager -> ExternalSecret (references secret) -> Kubernetes Secret

The ExternalSecret uses ClusterSecretStore (AWS SM backend) which authenticates via Pod Identity.

### Creating Secrets in AWS

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
- **Sync behaviour**: Refresh interval, error handling, and secret templates

## See Also

- [LEARNING_PATH.md](../LEARNING_PATH.md#23-external-secrets) - Step-by-step walkthrough
- [GLOSSARY.md](../GLOSSARY.md) - Definitions (Secrets Manager, Pod Identity)
- [eksauto/](../eksauto/) - Terraform that creates the IAM role and secret
- [External Secrets Operator docs](https://external-secrets.io/) - Official ESO documentation
