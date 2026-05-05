---
title: "Apps SSO"
description: "BookStack, Kanboard, and Woodpecker behind Keycloak/oauth2-proxy SSO."
weight: 30
icon: "right-to-bracket"
---

> Run [BookStack](https://www.bookstackapp.com/), [Kanboard](https://kanboard.org/), and [Woodpecker CI](https://woodpecker-ci.org/) behind a shared [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) + Keycloak SSO gate.

This is a local lab example: one namespace, BookStack with MariaDB, Kanboard with built-in SQLite, Woodpecker CI with SQLite, and one shared Keycloak/oauth2-proxy authentication layer behind a static Traefik edge.

## Quick Start

```bash
just apps-sso
```

`just apps-sso` creates/starts the local k3d cluster and deploys a static Traefik edge on NodePort `30080`. Browse to:

| App | URL | SSO login |
|-----|-----|-----------|
| BookStack | <http://bookstack.apps-sso.localtest.me:30080/> | Keycloak user `auditor` / `change-me-auditor-password` |
| Kanboard | <http://kanboard.apps-sso.localtest.me:30080/> | Keycloak user `auditor` / `change-me-auditor-password` |
| Woodpecker | <http://woodpecker.apps-sso.localtest.me:30080/> | Keycloak user `auditor` / `change-me-auditor-password`; Woodpecker also needs real forge OAuth for native login |
| Keycloak admin | <http://keycloak.apps-sso.localtest.me:30080/> | `admin` / `change-me-keycloak-admin` |
| oauth2-proxy callback | <http://oauth2.apps-sso.localtest.me:30080/oauth2/callback> | OIDC callback endpoint |

## What's Here

| File | Purpose |
|------|---------|
| `namespace.yaml` | Isolates both apps in `apps-sso` |
| `secrets.yaml` | Demo-only BookStack, oauth2-proxy, Keycloak, and Woodpecker secrets |
| `mariadb.yaml` | MariaDB for BookStack |
| `apps.yaml` | BookStack and Kanboard Deployments and Services |
| `woodpecker.yaml` | Woodpecker CI Deployment and Service |
| `keycloak.yaml` | Demo Keycloak realm, groups, user, OIDC client, Deployment, and Service |
| `oauth2-proxy.yaml` | Shared oauth2-proxy config, Deployment, and Service |
| `traefik.yaml` | Static Traefik routers, forwardAuth middleware, Deployment, and NodePort Service |

## Why This Shape?

- **BookStack needs MySQL/MariaDB**, so it gets a tiny MariaDB deployment.
- **Kanboard can run with SQLite**, so the demo keeps it as one container.
- **Woodpecker is included as a CI example**, protected by the same SSO edge. Its native login still needs real GitHub OAuth values before use.
- **One oauth2-proxy protects all app domains**, using a single Keycloak OIDC client and callback host.
- **Per-app domains stay separate**: BookStack, Kanboard, Woodpecker, Keycloak, and oauth2-proxy each get their own `*.apps-sso.localtest.me:30080` host.
- **Forwarded identity headers are explicit**: Traefik forwards `X-Auth-Request-User`, `X-Auth-Request-Email`, `X-Auth-Request-Preferred-Username`, `X-Auth-Request-Groups`, and `X-Auth-Request-Access-Token` from oauth2-proxy to the upstream request.
- **Traefik is the trust boundary**. Do not expose the app Services directly if you depend on forwarded identity or groups; only the local Traefik edge should be allowed to set these headers.
- **Secrets are demo values**, base64-encoded or plain `stringData` only for local readability. Generate real values outside a local lab.
- **`emptyDir` volumes keep the YAML short**. Data is lost when pods are recreated; use PVCs for anything you care about.

## SSO Pattern

The shared authentication flow follows the oauth2-proxy Keycloak OIDC pattern:

1. A user opens `bookstack.apps-sso.localtest.me:30080`, `kanboard.apps-sso.localtest.me:30080`, or `woodpecker.apps-sso.localtest.me:30080`.
2. Traefik forwardAuth calls in-cluster `http://oauth2-proxy.apps-sso.svc.cluster.local/oauth2/auth`; unauthenticated users are sent to public `http://oauth2.apps-sso.localtest.me:30080/oauth2/start`.
3. oauth2-proxy redirects unauthenticated users to Keycloak realm `apps`.
4. Keycloak issues tokens with the `groups` claim and realm roles. The demo user belongs to `/bookstack-users`, `/kanboard-users`, and `/woodpecker-users`, with matching realm roles.
5. oauth2-proxy authorizes the session with `allowed_groups` (or use `allowed_roles` for the included roles), then returns `X-Auth-Request-*` headers.
6. Traefik forwards the `X-Auth-Request-*` headers to the selected app.

Important docs used for this shape:

- oauth2-proxy Keycloak OIDC supports `--allowed-role` and `--allowed-group`, and Keycloak group membership can be mapped into the `groups` claim.
- oauth2-proxy `--set-xauthrequest` emits `X-Auth-Request-User`, `X-Auth-Request-Groups`, `X-Auth-Request-Email`, and `X-Auth-Request-Preferred-Username`; Traefik forwardAuth passes these headers upstream.
- Kanboard supports reverse-proxy identity headers via `REVERSE_PROXY_AUTH`/`REVERSE_PROXY_*` settings if you choose to make the upstream app consume these headers directly.
- BookStack supports native OIDC via `AUTH_METHOD=oidc`/`OIDC_*`; this example keeps OIDC centralized at oauth2-proxy so both apps use the same edge pattern.

The included BookStack, Kanboard, and Woodpecker containers still keep their native application login behavior. The SSO layer protects edge access and forwards identity/roles headers for audit/demo purposes. For production, also configure each upstream app to trust only the edge and consume external identity, or remove direct app logins.

## Cleanup

```bash
just apps-sso-clean
```
