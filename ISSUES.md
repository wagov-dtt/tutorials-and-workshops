# Audit Header

- **Audit date:** 2026-03-18
- **Latest commit:** `3bc7cd5` (`3bc7cd5143e273cb84535eb39d86f5ce4f748a34`) — `docs: switch AI guidance to oy`
- **Project context:** training/examples repo for DevOps, Kubernetes, EKS, Drupal, and small utility scripts. The docs explicitly prefer concise, local, learn-by-doing workflows over heavy CI. That context matters: some shortcuts are reasonable for throwaway local demos, but several patterns here are easy to cargo-cult into shared or cloud environments.
- **Codebase summary (`scc`):** 72 files, 3,968 lines, 3,075 lines of code, total complexity 16. The repo is now even more YAML-driven (42 files / 1,047 LOC). Remaining executable logic is small and concentrated in Terraform (7 files / 220 LOC / complexity 10) plus a few PHP support scripts (3 files / 150 LOC / complexity 5).
- **Standards and heuristics used:** OWASP ASVS 5.0.0, especially V4 (API and web service), V8 (authorization), V13 (configuration and secrets), and V15 (secure coding and architecture); plus grugbrain.dev guidance on keeping complexity low, preferring locality of behavior, and choosing boring/reproducible defaults.

## Prioritised Findings

## 1. Replace embedded and default credentials before they escape throwaway-local use
- **Priority:** P1
- **Status:** Open
- **Location:** `kustomize/databases/postgres.yaml:3-10`, `kustomize/databases/mysql.yaml:3-9`, `kustomize/databases/mongodb.yaml:3-9`, `kustomize/databases/elasticsearch.yaml:3-8`, `s3-pod-identity/base/mysql.yaml:3-10`, `eksauto/terraform/iam.tf:157-162`, `justfile:208-215`, `rclone/README.md:22-27`
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `13.2.3`, `13.3.1`, `13.3.2`
- **Finding:** The repo still teaches and embeds multiple real-looking defaults: `changeme`, `testpass`, `training-password-change-me`, and `admin/admin`. For a training repo this is understandable in isolated local flows, but it is too easy to copy these values into long-lived k3d, EKS, or demo environments.
- **Recommendation:** Keep at most one clearly labeled insecure-local example, but generate per-run credentials everywhere else. Make scripts fail fast when placeholders remain, move shared/AWS examples to generated secrets or external secret sources, and stop documenting `admin/admin` as a normal path.

## 2. Default EKS control plane access is public and unrestricted
- **Priority:** P1
- **Status:** Open
- **Location:** `eksauto/terraform/main.tf:48-52`
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `13.2.4`, `13.2.5`, `15.2.5`
- **Finding:** `cluster_endpoint_public_access = true` is enabled by default, with no obvious CIDR restriction. AWS auth still protects the cluster, but the control plane is intentionally exposed to the public Internet in the default training path.
- **Recommendation:** Default to private endpoint access or add a required `allowed_cidrs` variable for public access. If public access is necessary for training simplicity, document it as an explicit trade-off and keep the public path opt-in rather than default.

## 3. Secret scoping is broader than the repo’s own “local > global” guidance
- **Priority:** P1
- **Status:** Open
- **Location:** `secrets/base/clustersecretstore.yaml:1-18`, `secrets/base/externalsecret.yaml:11-27`, `secrets/README.md:5-24`
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `13.2.2`, `13.3.2`
- **Finding:** The docs correctly say local blast radius is better than global blast radius, but the implementation uses a cluster-wide `ClusterSecretStore`. That widens access patterns and makes accidental reuse across namespaces easier than necessary for a teaching example.
- **Recommendation:** Prefer namespace-scoped `SecretStore` for the demo unless the lesson specifically requires cross-namespace reuse. If `ClusterSecretStore` stays, call out the blast-radius trade-off directly in the manifest and README.

## 4. There are no `NetworkPolicy` resources anywhere in the Kubernetes examples
- **Priority:** P2
- **Status:** Open
- **Location:** repo-wide (`kustomize/`, `rclone/`, `s3-pod-identity/`, `argocd/`, `secrets/`, `drupal/kustomize/`) — no `NetworkPolicy` manifests found
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `13.2.4`, `15.2.5`
- **Finding:** Namespace isolation is taught, but network isolation is not. In practice this means any compromised pod can attempt lateral movement to databases, secret-sync components, or example admin surfaces.
- **Recommendation:** Add minimal, commented default-deny `NetworkPolicy` examples for the EKS-facing namespaces, then allow only the traffic paths each tutorial needs. This would improve security and also teach a better baseline.

## 5. Version drift is built into the toolchain and infrastructure defaults
- **Priority:** P2
- **Status:** Open
- **Location:** `mise.toml:1-13`, `eksauto/terraform/main.tf:4-10`, `eksauto/terraform/main.tf:67-72`, `justfile:208-214`
- **Category:** complexity
- **Standard reference:** OWASP ASVS 5.0.0 `15.1.1`, `15.2.1`, `15.2.4`; grugbrain.dev “complexity very bad” / “boring tech wins”
- **Finding:** The repo pulls `latest` for most CLI tools, auto-selects the latest EKS version, uses Terraform addons with `most_recent = true`, and runs `composer update --with-all-dependencies` during Drupal setup. This makes tutorials less reproducible and turns routine reruns into moving-target debugging.
- **Recommendation:** Pin tool versions, pin the EKS minor version and addon versions, and switch the Drupal setup flow to `composer install` against a committed lockfile unless the tutorial is explicitly about upgrade testing.

## 6. ArgoCD tracks `HEAD`, which weakens GitOps repeatability and change control
- **Priority:** P2
- **Status:** Open
- **Location:** `argocd/base/applicationset.yaml:15-28`
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `15.1.2`, `15.2.4`
- **Finding:** Both the generator revision and application `targetRevision` use `HEAD`. That means deployed state depends on a moving remote reference rather than an intentionally chosen branch, tag, or commit.
- **Recommendation:** Pin to a named branch at minimum, and use a tag or commit SHA for stronger reproducibility. If the repo wants to demonstrate “live GitOps,” document that `HEAD` is intentionally less reproducible than a pinned revision.

## 7. `just lint` does not validate the real Drupal Caddyfile path
- **Priority:** P2
- **Status:** Open
- **Location:** `justfile:279`, actual file is `drupal/Caddyfile`
- **Category:** complexity
- **Standard reference:** grugbrain.dev “locality of behavior” / “complexity very bad”
- **Finding:** The validation recipe runs `caddy fmt --diff drupal/conf/Caddyfile`, but `drupal/conf/` does not exist. So the repo advertises a config validation step that does not point at the active file.
- **Recommendation:** Validate `drupal/Caddyfile` directly and, if possible, add a runtime config validation step (`frankenphp validate` or equivalent). This is a small fix with outsized value because the Caddyfile contains most of the Drupal web hardening.

## 8. Container hardening is inconsistent across examples
- **Priority:** P2
- **Status:** Open
- **Location:** compare `kustomize/base/whoami-debug.yaml:16-36` with `rclone/base/deployment.yaml:22-34`, `s3-pod-identity/base/mysql.yaml:34-52`, `s3-pod-identity/base/debug.yaml:20-32`, `drupal/kustomize/pod.yaml:8-26`
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `13.4.2`, `13.4.5`, `15.2.5`
- **Finding:** The repo already knows how to harden a pod well (`whoami` uses `readOnlyRootFilesystem`, dropped capabilities, non-root, seccomp), but most other example workloads stop short of that baseline. The result is an inconsistent teaching signal: some examples model good defaults, others model “works, but looser than needed.”
- **Recommendation:** Create one shared “minimum hardened pod” pattern in comments/docs and apply it where images support it. Where a workload truly needs a writable root or weaker settings, document why.

## 9. Kubernetes availability safeguards are mostly absent: no probes, and several workloads lack resource controls
- **Priority:** P2
- **Status:** Open
- **Location:** repo-wide across `kustomize/databases/*.yaml`, `rclone/base/deployment.yaml`, `s3-pod-identity/base/mysql.yaml`, `s3-pod-identity/jobs/*.yaml`, `drupal/kustomize/pod.yaml`
- **Category:** performance
- **Standard reference:** OWASP ASVS 5.0.0 `13.1.2`, `13.1.3`, `15.2.2`
- **Finding:** No `livenessProbe`, `readinessProbe`, or `startupProbe` resources were found, and several workloads/jobs also omit CPU and memory requests/limits. For a training repo that is meant to be re-run locally and on EKS, this makes slow starts, transient failures, and noisy-neighbor effects harder to understand and recover from.
- **Recommendation:** Add basic probes to long-running services and set lightweight resource requests/limits for the remaining examples. If a manifest is intentionally probe-free for readability, note that explicitly.

## 10. `setup-eks` uses destructive retry logic that hides root causes
- **Priority:** P3
- **Status:** Open
- **Location:** `justfile:37-40`
- **Category:** complexity
- **Standard reference:** grugbrain.dev “complexity very bad” / “boring tech wins”
- **Finding:** `terraform apply -auto-approve || { terraform destroy -auto-approve; terraform apply -auto-approve; }` is clever in the bad way: a failing apply triggers an automatic destroy/recreate cycle. That can hide the original problem, widen blast radius, and make operator intent ambiguous.
- **Recommendation:** Fail fast on the first apply, print likely remediation steps, and provide a separate explicit recovery recipe if the project really wants a one-command “nuke and retry” path.

## Short Resolution Log

- Removed `analyse-site-ia/`, `ducklake/`, and `ducklake_test.py`; the previous findings about crawler complexity and DuckLake orchestration are resolved by deletion.
- Updated the codebase summary and surviving finding locations to match the smaller repo surface area and new `justfile` line numbers.
