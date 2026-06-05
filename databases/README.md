# databases/

Beginner local Kubernetes lab packaged as `charts/databases`.

It deploys to the `tutorials` kind cluster and installs:

- PostgreSQL
- MySQL
- MongoDB
- `whoami` debug HTTP app

## Quick start

```bash
just databases/deploy
just databases/smoke
kubectl get pods -n databases
```

The deploy recipe creates or reuses the local kind cluster, installs Linkerd, annotates the namespace for mesh injection, and applies the Helm chart.

## What to study

| Path | Purpose |
|------|---------|
| `../charts/databases/Chart.yaml` | Chart metadata |
| `../charts/databases/templates/postgres.yaml` | PostgreSQL Deployment/Service |
| `../charts/databases/templates/mysql.yaml` | MySQL Deployment/Service |
| `../charts/databases/templates/mongodb.yaml` | MongoDB Deployment/Service |
| `../charts/databases/templates/networkpolicy.yaml` | CNI NetworkPolicy teaching baseline |
| `../shared.just` | `_kind`, `_linkerd`, and `_platform` helpers |

## Useful commands

```bash
helm lint ../charts/databases
helm template databases ../charts/databases
kubectl -n databases get deploy,svc,pod
```

## Cleanup

```bash
just databases/clean
```

## References

- [kind](https://kind.sigs.k8s.io/)
- [Helm charts](https://helm.sh/docs/topics/charts/)
- [Linkerd automatic proxy injection](https://linkerd.io/2/features/proxy-injection/)
