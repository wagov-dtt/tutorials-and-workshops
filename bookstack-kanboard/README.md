# bookstack-kanboard/

> Run [BookStack](https://www.bookstackapp.com/) and [Kanboard](https://kanboard.org/) as simple Kubernetes containers.

This is a local lab example: one namespace, one BookStack deployment, one MariaDB deployment for BookStack, and one Kanboard deployment using its built-in SQLite storage.

## Quick Start

```bash
just bookstack-kanboard
```

Open the apps with port-forwarding:

```bash
kubectl -n bookstack-kanboard port-forward svc/bookstack 6875:80
kubectl -n bookstack-kanboard port-forward svc/kanboard 8080:80
```

Then browse to:

| App | URL | Default login |
|-----|-----|---------------|
| BookStack | <http://localhost:6875> | `admin@admin.com` / `password` |
| Kanboard | <http://localhost:8080> | `admin` / `admin` |

## What's Here

| File | Purpose |
|------|---------|
| `namespace.yaml` | Isolates both apps in `bookstack-kanboard` |
| `secrets.yaml` | Demo-only BookStack database credentials and app key |
| `mariadb.yaml` | MariaDB for BookStack |
| `apps.yaml` | BookStack and Kanboard Deployments and Services |

## Why This Shape?

- **BookStack needs MySQL/MariaDB**, so it gets a tiny MariaDB deployment.
- **Kanboard can run with SQLite**, so the demo keeps it as one container.
- **Services are ClusterIP**, so nothing is exposed until you run `kubectl port-forward`.
- **Secrets are demo values**, base64-encoded only because Kubernetes requires it. Generate real values outside a local lab.
- **`emptyDir` volumes keep the YAML short**. Data is lost when pods are recreated; use PVCs for anything you care about.

## Cleanup

```bash
just bookstack-kanboard-clean
```
