# Getting Started

Start here if you want the shortest path to a working local lab.

You will use **kind** for local Kubernetes, **Helm** for app packaging, **Linkerd** for mesh identity/policy, and simple **Traefik static config** for browser-facing examples. See [GLOSSARY.md](GLOSSARY.md) for definitions.

## Prerequisites

Install these first:

| Tool | What it does | Install |
|------|--------------|---------|
| [mise](https://mise.jdx.dev/) | Installs repo tool versions | `curl https://mise.run \| sh` |
| [Docker](https://docs.docker.com/get-docker/) | Runs kind nodes | Follow Docker docs |

`just prereqs` installs the rest from `mise.toml`, including `kind`, `kubectl`, `helm`, and the Linkerd CLI.

## First Run

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
2. `just doctor` prints tool, Docker, cluster, Linkerd, and AWS status without creating cloud resources.
3. `just databases/deploy` creates a kind cluster named `tutorials`.
4. Linkerd is installed and checked.
5. The database Helm chart deploys PostgreSQL, MySQL, MongoDB, and `whoami` into the `databases` namespace.
6. `just databases/smoke` verifies each database and the sample HTTP app.

## Explore What You Built

```bash
kubectl get pods -A
kubectl get pods -n databases
just commands
just urls
k9s
```

## Next Local Labs

```bash
just rclone/deploy
just rclone/smoke
just collab::deploy
just collab::smoke
kubectl -n collaboration port-forward svc/traefik 8080:80
```

Then open:

- <http://bookstack.localhost:8080> (`admin@admin.com` / `password`)
- <http://kanboard.localhost:8080> (`admin` / `admin`)
- <http://forgejo.localhost:8080> (create/use local users)

Optional SSO/Keycloak path: run `just collab::deploy-sso`, then open <http://keycloak.localhost:8080>.

## Cleanup

```bash
just databases/clean
just rclone/clean
just collab::clean
just clean-local
```

## Common Issues

### kind cluster will not start

```bash
kind delete cluster --name tutorials
just databases/deploy
```

### Linkerd command not found

Run `just prereqs` again, then rerun the recipe.

### Helm chart does not render

```bash
just check
helm template databases charts/databases
```

## Next

See [LEARNING_PATH.md](LEARNING_PATH.md) for the recommended order.
