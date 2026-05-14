# Learning Path

Suggested order: local first, then AWS.

## Level 1: Local Kubernetes with kind, Linkerd, and Helm

### 1.1 Local Databases

```bash
just databases/deploy
kubectl get pods -n databases
```

**What you learn**: kind, Linkerd mesh baseline, Helm releases, and simple stateful services.

**Detailed guide**: [databases/README.md](databases/README.md)

**Files to study**:
- `charts/databases/Chart.yaml`
- `charts/databases/templates/postgres.yaml`
- `charts/databases/templates/mysql.yaml`
- `charts/databases/templates/mongodb.yaml`
- `shared.just` - `_kind`, `_linkerd`, and `_platform`

---

### 1.2 rclone CSI Volumes

```bash
just rclone/rclone-test
kubectl -n rclone port-forward svc/filebrowser 8080:80
```

**What you learn**: CSI drivers, S3-compatible storage mounts, and Helm chart deployment for demo workloads.

**Detailed guide**: [rclone/README.md](rclone/README.md)

**Files to study**:
- `charts/rclone-demo/templates/deployment.yaml`
- `charts/rclone-demo/templates/linkerd-policy.yaml`

---

### 1.3 Collaboration Stack

```bash
just collaboration-stack/deploy
kubectl -n collaboration port-forward svc/traefik 8080:80
```

**What you learn**: Traefik static routing, Keycloak edge SSO, oauth2-proxy ForwardAuth, and Linkerd policy between Traefik, identity, and origins.

**Detailed guide**: [collaboration-stack/README.md](collaboration-stack/README.md)

**Files to study**:
- `charts/collaboration-stack/templates/traefik.yaml`
- `charts/collaboration-stack/templates/identity.yaml`
- `charts/collaboration-stack/templates/linkerd-policy.yaml`

---

### 1.4 Drupal CMS

```bash
just drupal/drupal-setup
cd drupal-hugo
ddev drush user:login
```

**Detailed guide**: [drupal-hugo/README.md](drupal-hugo/README.md)

## Level 2: AWS Examples

### 2.1 EKS Auto Mode

```bash
just eksauto/setup-eks
just eksauto/deploy
```

**Detailed guide**: [eksauto/README.md](eksauto/README.md)

### 2.2 S3 Pod Identity

```bash
just s3-pod-identity/s3-test
just s3-pod-identity/s3-restore
```

**Detailed guide**: [s3-pod-identity/README.md](s3-pod-identity/README.md)

### 2.3 External Secrets

```bash
just secrets/secrets-deploy
just secrets/secrets-test
```

**Detailed guide**: [secrets/README.md](secrets/README.md)

## Deployment Model

Kubernetes examples live under `charts/`. Deploy them directly with `helm upgrade --install`, or reconcile them from an orchestration cluster with ArgoCD. See [argocd/README.md](argocd/README.md).
