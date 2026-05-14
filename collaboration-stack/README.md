# collaboration-stack/

> Local collaboration lab: BookStack, Kanboard, Forgejo, Keycloak, oauth2-proxy, Traefik static config, and Linkerd policy.

This wrapper deploys the `charts/collaboration-stack` Helm chart to a local kind cluster.

## Quick Start

```bash
just collaboration-stack/deploy
kubectl -n collaboration port-forward svc/traefik 8080:80
```

Then open:

| App | URL | Login |
|-----|-----|-------|
| BookStack | <http://bookstack.localhost:8080> | Edge SSO first, then `admin@admin.com` / `password` |
| Kanboard | <http://kanboard.localhost:8080> | Edge SSO first, then `admin` / `admin` |
| Forgejo | <http://forgejo.localhost:8080> | Edge SSO first, then create/use local Forgejo users |
| Keycloak | <http://keycloak.localhost:8080> | Admin: `admin` / `admin-password` |
| Traefik dashboard | <http://traefik.localhost:8080> | No auth in this local demo |

SSO demo user:

```text
username: demo
password: demo-password
```

## Trust Boundary

Keycloak SSO is enforced at the **Traefik edge** for BookStack, Kanboard, and Forgejo. The apps still keep their own local users behind that gate, so double auth is intentional.

Future app-level trusted-header config should only trust headers from Traefik. Linkerd policy makes that defensible by allowing app-origin traffic only from Traefik's workload identity.

## What to Study

| Path | Purpose |
|------|---------|
| `../charts/collaboration-stack/templates/traefik.yaml` | Static routes and ForwardAuth middleware |
| `../charts/collaboration-stack/templates/identity.yaml` | Keycloak and oauth2-proxy |
| `../charts/collaboration-stack/templates/apps.yaml` | BookStack, Kanboard, and Forgejo |
| `../charts/collaboration-stack/templates/linkerd-policy.yaml` | mTLS authorization between edge, identity, apps, and DB |
| `justfile` | Local deploy/cleanup wrapper |

## Cleanup

```bash
just collaboration-stack/clean
```
