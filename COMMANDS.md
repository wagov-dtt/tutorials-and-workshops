# Command Index

Use these consistent verbs across labs.

| Lab | Deploy | Smoke/Test | URLs | Clean/Destroy | Cloud? |
|---|---|---|---|---|---|
| Tools/preflight | `just prereqs` / `just doctor` | `just check` | `just urls` | `just clean-local` | No |
| Databases | `just databases/deploy` | `just databases/smoke` | `just databases/urls` | `just databases/clean` | No |
| rclone CSI | `just rclone/deploy` | `just rclone/smoke` | `just rclone/urls` | `just rclone/clean` | No |
| Collaboration | `just collab::deploy` | `just collab::smoke` | `just collab::urls` | `just collab::clean` | No |
| Collaboration SSO | `just collab::deploy-sso` | `just collab::smoke` | `just collab::urls` | `just collab::clean` | No |
| Observability | `just observability/deploy` | `just observability/smoke` | `just observability/urls` | `just observability/clean` | No |
| Drupal/DDEV | `just drupal::deploy` | `just drupal::smoke` | `just drupal::urls` | `just drupal::clean` | No |
| EKS Auto Mode | `just eksauto/setup-eks` | `just eksauto/smoke` | n/a | `just eksauto/destroy-eks` | Yes |
| S3 Pod Identity | `just s3-pod-identity/deploy` | `just s3-pod-identity/smoke` | n/a | `just s3-pod-identity/clean` | Yes |
| External Secrets | `just secrets/deploy` | `just secrets/smoke` | n/a | `just secrets/clean` | Yes |

Validation split:

- `just check` — fast local chart/just syntax checks.
- `just check-cloud` — Terraform validation and cloud chart renders.
- `just check-security` — Trivy config scanning.
- `just lint` — full render/terraform/security validation.
- `just validate-local` — deploy and smoke-test local examples.
- `just validate-aws` — paid AWS validation path.

Before cloud labs, run:

```bash
just aws-preflight
```
