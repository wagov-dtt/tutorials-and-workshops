# Code Quality Review

> Generated with [oy-cli](https://github.com/wagov-dtt/oy-cli): `OY_MODEL=github-copilot/gpt-5.5 oy review` · 2026-06-05

## Verdict

Needs work

## Findings summary

| Severity | Finding | Reference |
|---|---|---|
| High | Disabled SSO still deploys and exposes the full Keycloak/oauth2-proxy plane | `charts/collaboration-stack/values.yaml:3`, `charts/collaboration-stack/templates/identity.yaml:1` |
| High | Helm charts mix hard-coded namespaces with `--create-namespace`, crossing release ownership boundaries | `charts/s3-pod-identity/templates/base/namespace.yaml:1`, `secrets/justfile:15` |
| Medium | Observability deployment is orchestration-by-copy-paste instead of one deployable chart/boundary | `observability/justfile:21` |
| Medium | Tool, cluster, addon, and image versions float on “latest”/auto-latest | `mise.toml:2`, `eksauto/terraform/main.tf:5`, `charts/collaboration-stack/templates/apps.yaml:18` |
| Medium | Drupal example carries a broad mutable dependency graph for a narrow lab | `drupal-hugo/composer.json:18`, `drupal-hugo/justfile:20` |
| Low | rclone demo scales a stateful UI to 3 replicas with per-pod `emptyDir` state | `charts/rclone-demo/templates/deployment.yaml:66` |

## Detailed findings

### High — Disabled SSO still deploys and exposes the full identity plane

**Evidence**

- `charts/collaboration-stack/values.yaml:3` defaults `sso.enabled: false`.
- `charts/collaboration-stack/templates/identity.yaml:1` still unconditionally deploys Keycloak.
- `charts/collaboration-stack/templates/identity.yaml:74` still unconditionally deploys oauth2-proxy.
- `charts/collaboration-stack/templates/traefik.yaml:24` keeps Keycloak/Auth routers in the default Traefik config.
- `collaboration-stack/justfile:21` waits for Keycloak and oauth2-proxy on every default deploy.

**Design impact**

The flag only disables some ForwardAuth middleware, not the feature. The default local collaboration stack still pulls and runs large identity components, opens extra routes/policies, adds startup waits, and makes the “optional SSO” product shape hard to reason about. This is scope creep in the hot path.

**Concrete simplification**

Make the flag own the whole feature:

- Wrap `identity.yaml`, `keycloak-realm.yaml`, oauth2-proxy/keycloak services, Traefik `auth`/`keycloak` routers, related Linkerd policies, secrets, and justfile waits under `.Values.sso.enabled`.
- Or delete the flag and document identity as always-on.
- Prefer the first: keep the default demo to BookStack/Kanboard/Forgejo + Traefik, and provide a separate SSO overlay for study.

---

### High — Helm charts mix hard-coded namespaces with release namespace creation

**Evidence**

- `s3-pod-identity/justfile:22` installs with `helm upgrade --install ... -n s3-test --create-namespace`.
- `charts/s3-pod-identity/templates/base/namespace.yaml:1` also creates the `s3-test` namespace.
- Many s3-pod-identity templates hard-code `namespace: s3-test`, e.g. `charts/s3-pod-identity/templates/base/mysql.yaml:5`.
- `secrets/justfile:15` installs the External Secrets operator into `external-secrets`.
- `charts/secrets-demo/templates/namespace.yaml:1` makes the demo chart also declare `external-secrets`, a namespace owned operationally by the operator release.
- `charts/secrets-demo/templates/namespace.yaml:7` also declares `secrets-demo` while the wrapper installs with `-n secrets-demo --create-namespace`.

**Design impact**

Namespace ownership is split between Helm CLI bootstrap, app charts, and unrelated operator releases. That makes charts non-relocatable and risks Helm install/adoption failures when a namespace already exists without the current release’s ownership metadata. It also lets an app demo chart mutate cluster/operator boundaries it should not own.

**Concrete simplification**

Use one namespace ownership model:

- Remove `Namespace` manifests from app/demo charts.
- Omit `metadata.namespace` from namespaced templates, or use `{{ .Release.Namespace }}` only where needed.
- Let wrapper recipes create namespaces with `kubectl create namespace ... --dry-run=client | kubectl apply -f -` or Helm `--create-namespace`.
- Keep `external-secrets` namespace owned only by the External Secrets operator install; the `secrets-demo` chart should only render demo resources into its release namespace.

---

### Medium — Observability deployment is orchestration-by-copy-paste instead of one deployable boundary

**Evidence**

- `observability/justfile:21` `deploy`, `observability/justfile:53` `deploy-s3`, and `observability/justfile:88` `deploy-eksauto-cloudwatch` repeat the VictoriaMetrics, VictoriaLogs, VictoriaTraces, Grafana, and OTel collector install sequence.
- Raw observability resources live outside a chart: `observability/ui-proxy.yaml:1` and `observability/linkerd-policy.yaml:1`.
- The top-level lint path manually templates each upstream observability chart instead of validating one repo-owned observability artifact.

**Design impact**

Release names, waits, values files, retention, policy, proxy ports, and collector overlays must stay synchronized across several shell recipes and raw manifests. That is non-atomic change surface: adding one backend or changing one service name requires edits in multiple places. It also conflicts with the repo’s stated model that examples are packaged under `charts/`.

**Concrete simplification**

Create a small `charts/observability` wrapper chart:

- Add dependencies for the upstream Victoria/Grafana/OpenTelemetry charts.
- Move `ui-proxy.yaml` and `linkerd-policy.yaml` into templates.
- Keep environment-specific values files: local, S3 fan-out, EKS CloudWatch.
- Collapse just recipes to one `helm upgrade --install observability ../charts/observability -f ...` plus waits/smoke.

If an umbrella chart feels too heavy, the smaller fix is extracting private just recipes like `_install-hot-store`, `_install-ui-policy`, and `_install-otel-local/_s3/_cloudwatch` to delete the repeated blocks.

---

### Medium — Versions float across tools, cluster, addons, and images

**Evidence**

- `mise.toml:2` and following entries use `latest` for core tools (`awscli`, `helm`, `just`, `kind`, `kubectl`, `terraform`, `ddev`, `rclone`, etc.).
- `eksauto/terraform/main.tf:5` discovers cluster versions dynamically, and `eksauto/terraform/main.tf:10` uses the first returned version.
- `eksauto/terraform/main.tf:55` uses `most_recent = true` for EKS addons.
- `charts/collaboration-stack/templates/apps.yaml:18` uses `lscr.io/linuxserver/bookstack:latest`; `charts/collaboration-stack/templates/apps.yaml:86` uses `kanboard/kanboard:latest`.

**Design impact**

The lab is not reproducible. A user running the same recipe next month may get different CLIs, Kubernetes versions, addons, and app images. That creates review noise, validation drift, and silent dependency/artifact growth.

**Concrete simplification**

Pin by default and update intentionally:

- Pin `mise.toml` tool versions.
- Make EKS Kubernetes version an explicit variable with a pinned default.
- Pin addon versions or document a deliberate upgrade path.
- Move image tags into chart values and pin exact versions; use Renovate or a `just update-tools` recipe for controlled bumps.

---

### Medium — Drupal example carries a broad mutable dependency graph for a narrow lab

**Evidence**

- `drupal-hugo/composer.json:18` starts a large Drupal CMS dependency list.
- `drupal-hugo/composer.json:21` includes AI-related providers/modules such as `drupal/ai`, with further Anthropic/OpenAI/AmazeeIO providers in the same require block.
- `drupal-hugo/justfile:20` runs `ddev composer update --with-all-dependencies`.
- `drupal-hugo/justfile:21` mutates dependencies again with `ddev composer require ...`.

**Design impact**

For a repo whose Drupal README frames this as a Drupal/Hugo/static-site experiment, the checked-in dependency surface is very wide and setup is non-reproducible. `composer update` means every setup can produce a different graph; runtime `composer require` means the repo state is not the whole source of truth.

**Concrete simplification**

Narrow and freeze the example:

- Commit and use a lockfile-backed `composer install` path.
- Remove modules/providers not needed for the lab goal.
- If the intent is “vanilla Drupal CMS,” avoid carrying the full generated project in the main repo; generate it in the DDEV recipe or isolate it as its own project boundary.
- Keep `drupal-setup` idempotent: no unconditional `composer update` or repeated `composer require`.

---

### Low — rclone demo scales a stateful UI with per-pod local state

**Evidence**

- `charts/rclone-demo/templates/deployment.yaml:66` sets `filebrowser` `replicas: 3`.
- `charts/rclone-demo/templates/deployment.yaml:96` gives each replica its own `emptyDir` database.
- All replicas mount the same rclone CSI-backed `/srv` volume.

**Design impact**

The local demo pays for three UI pods but each has separate Filebrowser database state. A Service can route users to different pods with different UI/config/auth state, which is unnecessary complexity for a storage-mount demo.

**Concrete simplification**

Set `replicas: 1` for the demo. If multi-replica behavior is a learning goal, use one shared database/PVC and document the concurrency model; otherwise delete the scale-out branch.

## Machine-readable findings

```json oy-findings
[
  {
    "source": "oy",
    "severity": "high",
    "title": "Disabled SSO still deploys and exposes the full identity plane",
    "locations": [
      {
        "path": "charts/collaboration-stack/values.yaml",
        "line": 3,
        "symbol": "sso.enabled"
      },
      {
        "path": "charts/collaboration-stack/templates/identity.yaml",
        "line": 1,
        "symbol": "Deployment/keycloak"
      },
      {
        "path": "charts/collaboration-stack/templates/identity.yaml",
        "line": 74,
        "symbol": "Deployment/oauth2-proxy"
      },
      {
        "path": "collaboration-stack/justfile",
        "line": 21,
        "symbol": "_wait"
      }
    ],
    "evidence": "The chart defaults sso.enabled to false, but identity.yaml still deploys Keycloak and oauth2-proxy, Traefik still exposes identity routes, and the deploy wrapper waits for both components.",
    "body": "Make .Values.sso.enabled own the whole feature: wrap identity deployments, routes, policies, secrets, and waits under the flag, or delete the flag and document identity as always-on. The current default pays the resource, image, route, and policy cost for a disabled feature.",
    "category": "scope-control"
  },
  {
    "source": "oy",
    "severity": "high",
    "title": "Charts mix hard-coded namespaces with release namespace creation",
    "locations": [
      {
        "path": "s3-pod-identity/justfile",
        "line": 22,
        "symbol": "s3-test"
      },
      {
        "path": "charts/s3-pod-identity/templates/base/namespace.yaml",
        "line": 1,
        "symbol": "Namespace/s3-test"
      },
      {
        "path": "charts/s3-pod-identity/templates/base/mysql.yaml",
        "line": 5,
        "symbol": "metadata.namespace"
      },
      {
        "path": "secrets/justfile",
        "line": 15,
        "symbol": "secrets-deploy"
      },
      {
        "path": "charts/secrets-demo/templates/namespace.yaml",
        "line": 1,
        "symbol": "Namespace/external-secrets"
      }
    ],
    "evidence": "Wrappers install releases with -n/--create-namespace while charts also create or hard-code those namespaces; secrets-demo also declares the external-secrets operator namespace owned by a separate release.",
    "body": "Remove Namespace resources from app charts and omit hard-coded metadata.namespace values. Let wrappers/bootstrap own namespace creation, and keep the External Secrets operator namespace owned only by the operator install.",
    "category": "helm-boundary"
  },
  {
    "source": "oy",
    "severity": "medium",
    "title": "Observability deployment is duplicated shell orchestration rather than one deployable unit",
    "locations": [
      {
        "path": "observability/justfile",
        "line": 21,
        "symbol": "deploy"
      },
      {
        "path": "observability/justfile",
        "line": 53,
        "symbol": "deploy-s3"
      },
      {
        "path": "observability/justfile",
        "line": 88,
        "symbol": "deploy-eksauto-cloudwatch"
      },
      {
        "path": "observability/ui-proxy.yaml",
        "line": 1,
        "symbol": "observability-ui"
      },
      {
        "path": "observability/linkerd-policy.yaml",
        "line": 1,
        "symbol": "Linkerd policy"
      }
    ],
    "evidence": "Three observability recipes repeat the same Victoria*/Grafana/OTel install sequence, while proxy and policy resources live as raw manifests outside a chart.",
    "body": "Create a small charts/observability wrapper chart with dependencies and templates for ui-proxy and Linkerd policy, then drive local/S3/EKS through values overlays. At minimum, extract shared private just recipes to remove the repeated install blocks.",
    "category": "orchestration"
  },
  {
    "source": "oy",
    "severity": "medium",
    "title": "Tool, cluster, addon, and image versions float",
    "locations": [
      {
        "path": "mise.toml",
        "line": 2,
        "symbol": "tools"
      },
      {
        "path": "eksauto/terraform/main.tf",
        "line": 5,
        "symbol": "aws_eks_cluster_versions"
      },
      {
        "path": "eksauto/terraform/main.tf",
        "line": 55,
        "symbol": "addons"
      },
      {
        "path": "charts/collaboration-stack/templates/apps.yaml",
        "line": 18,
        "symbol": "bookstack image"
      }
    ],
    "evidence": "mise uses latest for core tooling, Terraform selects the latest EKS version/addons, and some workload images use latest tags.",
    "body": "Pin versions by default and update intentionally. Use explicit mise versions, an EKS version variable with a pinned default, controlled addon versions, and chart values for pinned image tags or digests.",
    "category": "reproducibility"
  },
  {
    "source": "oy",
    "severity": "medium",
    "title": "Drupal example carries a broad mutable dependency graph",
    "locations": [
      {
        "path": "drupal-hugo/composer.json",
        "line": 18,
        "symbol": "require"
      },
      {
        "path": "drupal-hugo/composer.json",
        "line": 21,
        "symbol": "drupal/ai"
      },
      {
        "path": "drupal-hugo/justfile",
        "line": 20,
        "symbol": "drupal-setup"
      }
    ],
    "evidence": "The Drupal project requires a large CMS/module set including AI providers, and setup runs composer update plus composer require at runtime.",
    "body": "Freeze the dependency graph with composer install from a committed lockfile, remove modules not needed for the lab, and avoid mutating composer requirements during setup. If vanilla Drupal CMS is the goal, generate or isolate it rather than carrying the whole mutable scaffold in the main repo.",
    "category": "dependency-footprint"
  },
  {
    "source": "oy",
    "severity": "low",
    "title": "rclone demo scales Filebrowser with per-pod local state",
    "locations": [
      {
        "path": "charts/rclone-demo/templates/deployment.yaml",
        "line": 66,
        "symbol": "Deployment/filebrowser replicas"
      },
      {
        "path": "charts/rclone-demo/templates/deployment.yaml",
        "line": 96,
        "symbol": "database emptyDir"
      }
    ],
    "evidence": "filebrowser runs with replicas: 3 while each pod has its own emptyDir database and all pods share the mounted S3-like data volume.",
    "body": "Use replicas: 1 for the local storage demo, or provide a shared database/PVC if multi-replica UI behavior is intentional.",
    "category": "demo-simplicity"
  }
]
```
