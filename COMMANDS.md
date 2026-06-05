# Command Index

Consistent commands make the labs easier to teach and debug. Most labs use this shape:

```text
just <lab>/deploy -> just <lab>/smoke -> just <lab>/urls -> just <lab>/clean
```

Some directories use `just` module aliases, such as `collab::deploy` and `drupal::deploy`.

## Lab commands

| Lab | Deploy | Smoke/test | URLs | Clean/destroy | Cloud? |
|-----|--------|------------|------|---------------|--------|
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

## Validation commands

| Command | Scope |
|---------|-------|
| `just check` | Fast local chart and `justfile` checks |
| `just check-cloud` | Terraform validation and cloud chart renders |
| `just check-security` | [Trivy](https://aquasecurity.github.io/trivy/) config scanning |
| `just lint` | Full render, Terraform, and security validation |
| `just validate-local` | Deploy and smoke-test local examples |
| `just validate-aws` | Paid AWS validation path with an inspection pause |

## Before cloud labs

```bash
just aws-preflight
```

This prints the active AWS account/region and the paid-resource blast radius before you create EKS resources.

## Helpful references

- [just manual](https://just.systems/man/en/)
- [kubectl command reference](https://kubernetes.io/docs/reference/kubectl/)
- [Helm command docs](https://helm.sh/docs/helm/)
- [Terraform CLI docs](https://developer.hashicorp.com/terraform/cli)
