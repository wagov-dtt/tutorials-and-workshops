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
- **Location:** `charts/databases/templates/postgres.yaml:3-10`, `charts/databases/templates/mysql.yaml:3-8`, `charts/databases/templates/mongodb.yaml:3-9`, `charts/s3-pod-identity/templates/base/mysql.yaml:3-10`, `eksauto/terraform/iam.tf:157-162`, `rclone/README.md:22-27`
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `13.2.3`, `13.3.1`, `13.3.2`
- **Finding:** The repo still teaches and embeds multiple real-looking defaults: `changeme`, `testpass`, `training-password-change-me`, and `admin/admin`. For a training repo this is understandable in isolated local flows, but it is too easy to copy these values into long-lived kind, EKS, or demo environments.
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
- **Location:** `charts/secrets-demo/templates/clustersecretstore.yaml:1-18`, `charts/secrets-demo/templates/externalsecret.yaml:1-27`, `secrets/README.md:5-24`
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `13.2.2`, `13.3.2`
- **Finding:** The docs correctly say local blast radius is better than global blast radius, but the implementation uses a cluster-wide `ClusterSecretStore`. That widens access patterns and makes accidental reuse across namespaces easier than necessary for a teaching example.
- **Recommendation:** Prefer namespace-scoped `SecretStore` for the demo unless the lesson specifically requires cross-namespace reuse. If `ClusterSecretStore` stays, call out the blast-radius trade-off directly in the manifest and README.

## 4. There are no `NetworkPolicy` resources anywhere in the Kubernetes examples
- **Priority:** P2
- **Status:** Open
- **Location:** repo-wide Kubernetes examples (`charts/`, `rclone/`, `s3-pod-identity/`, `argocd/`, `secrets/`) — no `NetworkPolicy` manifests found
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `13.2.4`, `15.2.5`
- **Finding:** Namespace isolation is taught, but network isolation is not. In practice this means any compromised pod can attempt lateral movement to databases, secret-sync components, or example admin surfaces.
- **Recommendation:** Add minimal, commented default-deny `NetworkPolicy` examples for the EKS-facing namespaces, then allow only the traffic paths each tutorial needs. This would improve security and also teach a better baseline.

## 5. Version drift is built into the toolchain and infrastructure defaults
- **Priority:** P2
- **Status:** Open
- **Location:** `mise.toml:1-13`, `eksauto/terraform/main.tf:4-10`, `eksauto/terraform/main.tf:67-72`, `drupal-hugo/justfile:14-18`
- **Category:** complexity
- **Standard reference:** OWASP ASVS 5.0.0 `15.1.1`, `15.2.1`, `15.2.4`; grugbrain.dev “complexity very bad” / “boring tech wins”
- **Finding:** The repo pulls `latest` for most CLI tools, auto-selects the latest EKS version, uses Terraform addons with `most_recent = true`, and runs `composer update --with-all-dependencies` during Drupal setup. This makes tutorials less reproducible and turns routine reruns into moving-target debugging.
- **Recommendation:** Pin tool versions, pin the EKS minor version and addon versions, and switch the Drupal setup flow to `composer install` against a committed lockfile unless the tutorial is explicitly about upgrade testing.

## 6. ArgoCD manifests were removed from the repo
- **Priority:** P2
- **Status:** Fixed
- **Location:** `argocd/README.md`
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `15.1.2`, `15.2.4`
- **Finding:** The previous in-repo ArgoCD ApplicationSet used a moving revision, which weakened repeatability.
- **Recommendation:** Keep this repo chart-focused. If ArgoCD manifests are reintroduced, pin a named branch, tag, or commit rather than a moving remote reference.

## 7. Drupal validation path drift was removed from the active lint path
- **Priority:** P2
- **Status:** Fixed
- **Location:** `drupal-hugo/justfile`
- **Category:** complexity
- **Standard reference:** grugbrain.dev “locality of behavior” / “complexity very bad”
- **Finding:** The old lint recipe referenced a deleted Drupal web-server config path. The active Drupal example is now a DDEV wrapper under `drupal-hugo/`.
- **Recommendation:** Keep validation commands close to the files and tools each example actually owns.

## 8. Container hardening is inconsistent across examples
- **Priority:** P2
- **Status:** Partial (Dockerfile USER www-data added; other workloads still need securityContext)
- **Location:** compare `charts/databases/templates/whoami-debug.yaml` with the remaining app/database workloads under `charts/` and `s3-pod-identity/`
- **Category:** security
- **Standard reference:** OWASP ASVS 5.0.0 `13.4.2`, `13.4.5`, `15.2.5`
- **Finding:** The repo already knows how to harden a pod well (`whoami` uses `readOnlyRootFilesystem`, dropped capabilities, non-root, seccomp), but most other example workloads stop short of that baseline. The result is an inconsistent teaching signal: some examples model good defaults, others model “works, but looser than needed.”
- **Recommendation:** Create one shared “minimum hardened pod” pattern in comments/docs and apply it where images support it. Where a workload truly needs a writable root or weaker settings, document why.

## 9. Kubernetes availability safeguards are mostly absent: no probes, and several workloads lack resource controls
- **Priority:** P2
- **Status:** Open
- **Location:** repo-wide across `charts/databases/*.yaml`, `charts/rclone-demo/*.yaml`, `charts/s3-pod-identity/templates/base/mysql.yaml`, and `charts/s3-pod-identity/templates/jobs/*.yaml`
- **Category:** performance
- **Standard reference:** OWASP ASVS 5.0.0 `13.1.2`, `13.1.3`, `15.2.2`
- **Finding:** No `livenessProbe`, `readinessProbe`, or `startupProbe` resources were found, and several workloads/jobs also omit CPU and memory requests/limits. For a training repo that is meant to be re-run locally and on EKS, this makes slow starts, transient failures, and noisy-neighbor effects harder to understand and recover from.
- **Recommendation:** Add basic probes to long-running services and set lightweight resource requests/limits for the remaining examples. If a manifest is intentionally probe-free for readability, note that explicitly.

## 10. EKS setup now fails fast instead of destroying on retry
- **Priority:** P3
- **Status:** Fixed
- **Location:** `eksauto/justfile:12-15`
- **Category:** complexity
- **Standard reference:** grugbrain.dev “complexity very bad” / “boring tech wins”
- **Finding:** The current `setup-eks` recipe runs a single Terraform apply and does not automatically destroy/recreate on failure.
- **Recommendation:** Keep destructive recovery as an explicit operator action, not an implicit retry side effect.

## Short Resolution Log

- Removed `analyse-site-ia/`, `ducklake/`, and `ducklake_test.py`; the previous findings about crawler complexity and DuckLake orchestration are resolved by deletion.
- Updated the codebase summary and surviving finding locations to match the smaller repo surface area and new `justfile` line numbers.

### Fixes applied

- **Issue #7 (Drupal validation path):** Removed the stale validation path from the active lint flow. → **Closed.**
- **Issue #8 (Container hardening):** Previous Drupal container hardening note is obsolete after the DDEV migration; other workloads still need securityContext work. → **Partial.**
- **Local search engine workload:** Removed the former single-node search service from the local database chart to keep the beginner lab smaller.
- **MySQL local-infile:** Removed `--local-infile=1` from `charts/s3-pod-identity/templates/base/mysql.yaml`.
- **Dependabot coverage:** Added `terraform` (`/eksauto/terraform`), `docker` (`/drupal`), and `github-actions` ecosystems to `.github/dependabot.yml`.
