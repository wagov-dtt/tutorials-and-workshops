# collaboration-stack/

Local collaboration lab for BookStack, Kanboard, Forgejo, Traefik, Linkerd policy, and optional Keycloak/oauth2-proxy SSO.

The wrapper deploys `charts/collaboration-stack` to the local kind cluster.

## Quick start

```bash
just collab::deploy
just collab::smoke
kubectl -n collaboration port-forward svc/traefik 8080:80
```

Then open:

| App | URL | Local demo login |
|-----|-----|------------------|
| BookStack | <http://bookstack.localhost:8080> | `admin@admin.com` / `password` |
| Kanboard | <http://kanboard.localhost:8080> | `admin` / `admin` |
| Forgejo | <http://forgejo.localhost:8080> | Create or use local Forgejo users |
| Traefik dashboard | <http://traefik.localhost:8080> | No auth in this local demo |

These credentials are for local throwaway labs only.

## Optional SSO path

Deploy the Keycloak/oauth2-proxy variant:

```bash
just collab::deploy-sso
kubectl -n collaboration port-forward svc/traefik 8080:80
```

Keycloak is then available at <http://keycloak.localhost:8080>.

Demo identities:

| Identity | Username | Password |
|----------|----------|----------|
| Keycloak admin | `admin` | `admin-password` |
| Demo user | `demo` | `demo-password` |

To study the rendered SSO manifests without deploying:

```bash
helm template collaboration-stack ../charts/collaboration-stack --set sso.enabled=true
```

## Trust boundary

Browser traffic enters at the Traefik edge. App origins stay internal. Any trusted-header or SSO integration should trust headers only from Traefik.

Linkerd policy supports that model by allowing app-origin traffic only from the expected workload identities. CNI `NetworkPolicy` examples document the intended network boundary for clusters that enforce it.

## What to study

| Path | Purpose |
|------|---------|
| `../charts/collaboration-stack/templates/traefik.yaml` | Static routes and ForwardAuth middleware |
| `../charts/collaboration-stack/templates/identity.yaml` | Keycloak and oauth2-proxy demo components |
| `../charts/collaboration-stack/templates/apps.yaml` | BookStack, Kanboard, and Forgejo |
| `../charts/collaboration-stack/templates/linkerd-policy.yaml` | mTLS authorization between edge, identity, apps, and DBs |
| `../charts/collaboration-stack/templates/networkpolicy.yaml` | CNI default-deny and allow-list examples |
| `justfile` | Local deploy/smoke/cleanup wrapper |

## Cleanup

```bash
just collab::clean
```

## References

- [Traefik file provider](https://doc.traefik.io/traefik/providers/file/)
- [Linkerd authorization policy](https://linkerd.io/2/features/policy/)
- [Keycloak documentation](https://www.keycloak.org/documentation)
- [oauth2-proxy documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
