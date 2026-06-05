# GitHub Configuration

Repository automation and maintenance settings.

## What is here

| File | Purpose |
|------|---------|
| `dependabot.yml` | Dependency update checks for GitHub Actions, Docker, Terraform, and package manifests |

## Guidelines

- Keep automation small and directly useful for validating the examples.
- Prefer checks that can run without cloud credentials.
- Document any workflow that creates cloud resources, including cost and cleanup.

## References

- [Dependabot options reference](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)
- [GitHub Actions docs](https://docs.github.com/en/actions)
