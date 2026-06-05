# Getting Started

Use this path for the quickest working local lab. It creates no cloud resources.

You will use:

- [kind](https://kind.sigs.k8s.io/) for local Kubernetes
- [Helm](https://helm.sh/docs/) for app packaging
- [Linkerd](https://linkerd.io/2/) for mesh identity and policy
- [Traefik file/static config](https://doc.traefik.io/traefik/providers/file/) for browser-facing examples
- [just](https://just.systems/man/en/) for repeatable commands

See [GLOSSARY.md](GLOSSARY.md) for short definitions.

## Prerequisites

| Tool | Why | Install |
|------|-----|---------|
| [mise](https://mise.jdx.dev/) | Installs repo tool versions from `mise.toml` | `curl https://mise.run \| sh` |
| [Docker](https://docs.docker.com/get-docker/) | Runs kind cluster nodes | Follow Docker's docs |

`just prereqs` installs the remaining tools, including `kind`, `kubectl`, `helm`, and the Linkerd CLI.

## First run

```bash
git clone https://github.com/wagov-dtt/tutorials-and-workshops
cd tutorials-and-workshops

just prereqs
just doctor
just databases/deploy
just databases/smoke
```

What happens:

1. `just prereqs` installs tools from `mise.toml`.
2. `just doctor` prints local tool, Docker, cluster, Linkerd, and AWS status without creating cloud resources.
3. `just databases/deploy` creates or reuses the `tutorials` kind cluster.
4. Linkerd is installed and checked.
5. The database Helm chart deploys PostgreSQL, MySQL, MongoDB, and `whoami` into the `databases` namespace.
6. `just databases/smoke` verifies the services.

## Explore the cluster

```bash
kubectl get pods -A
kubectl get pods -n databases
just commands
just urls
k9s
```

If you do not use [k9s](https://k9scli.io/), `kubectl get`, `kubectl describe`, and `kubectl logs` are enough for these labs.

## Next local labs

```bash
just rclone/deploy
just rclone/smoke
just collab::deploy
just collab::smoke
kubectl -n collaboration port-forward svc/traefik 8080:80
```

Then open:

| App | URL | Local demo login |
|-----|-----|------------------|
| BookStack | <http://bookstack.localhost:8080> | `admin@admin.com` / `password` |
| Kanboard | <http://kanboard.localhost:8080> | `admin` / `admin` |
| Forgejo | <http://forgejo.localhost:8080> | Create or use local users |

Optional SSO path:

```bash
just collab::deploy-sso
kubectl -n collaboration port-forward svc/traefik 8080:80
```

Then open <http://keycloak.localhost:8080>.

## Cleanup

Clean individual labs:

```bash
just databases/clean
just rclone/clean
just collab::clean
```

Delete the whole local cluster:

```bash
just clean-local
```

## Common issues

### kind cluster will not start

```bash
kind delete cluster --name tutorials
just databases/deploy
```

Also check Docker is running and has enough CPU/memory.

### Linkerd command not found

Run `just prereqs`, then rerun the failed recipe.

### Helm chart does not render

```bash
just check
helm template databases charts/databases
```

### Browser URL does not load

Make sure the port-forward command is still running:

```bash
kubectl -n collaboration port-forward svc/traefik 8080:80
```

## Next

Continue with [LEARNING_PATH.md](LEARNING_PATH.md).
