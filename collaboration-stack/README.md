# collaboration-stack/

> Local collaboration lab: BookStack, Kanboard, Forgejo, optional Keycloak/oauth2-proxy SSO, Traefik static config, and Linkerd policy.

This wrapper deploys the `charts/collaboration-stack` Helm chart to a local kind cluster.

## Quick Start

```bash
just collab::deploy
just collab::smoke
kubectl -n collaboration port-forward svc/traefik 8080:80
```

Then open:

| App | URL | Login |
|-----|-----|-------|
| BookStack | <http://bookstack.localhost:8080> | `admin@admin.com` / `password` |
| Kanboard | <http://kanboard.localhost:8080> | `admin` / `admin` |
| Forgejo | <http://forgejo.localhost:8080> | Create/use local Forgejo users |
| Traefik dashboard | <http://traefik.localhost:8080> | No auth in this local demo |

Keycloak demo user:

```text
username: demo
password: demo-password
```

## Trust Boundary

Browser traffic enters at the **Traefik edge**. BookStack, Kanboard, and Forgejo keep their own local users in this simple local deploy.

Future SSO or trusted-header config should only trust headers from Traefik. Linkerd policy makes that defensible by allowing app-origin traffic only from Traefik's workload identity.

Edge SSO is optional and disabled by default for the local demo. To render it for study:

```bash
helm template collaboration-stack ../charts/collaboration-stack --set sso.enabled=true
```

To deploy the SSO variant locally:

```bash
just collab::deploy-sso
```

Then Keycloak is available at <http://keycloak.localhost:8080> with admin `admin` / `admin-password` and demo user `demo` / `demo-password`.

## What to Study

| Path | Purpose |
|------|---------|
| `../charts/collaboration-stack/templates/traefik.yaml` | Static routes and ForwardAuth middleware |
| `../charts/collaboration-stack/templates/identity.yaml` | Keycloak and oauth2-proxy demo components |
| `../charts/collaboration-stack/templates/apps.yaml` | BookStack, Kanboard, and Forgejo |
| `../charts/collaboration-stack/templates/linkerd-policy.yaml` | mTLS authorization between edge, identity, apps, and DB |
| `../charts/collaboration-stack/templates/networkpolicy.yaml` | CNI-level default-deny and allow-list examples |
| `justfile` | Local deploy/cleanup wrapper |

## Cleanup

```bash
just collab::clean
```
