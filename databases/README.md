# databases/

Local kind database lab packaged as `charts/databases`.

It installs:

- PostgreSQL
- MySQL
- MongoDB
- `whoami` debug app

```bash
just databases/deploy
kubectl get pods -n databases
```

The recipe creates/uses the `tutorials` kind cluster, installs Linkerd, annotates the namespace for mesh injection, and applies the Helm chart.

Cleanup:

```bash
just databases/clean
```
