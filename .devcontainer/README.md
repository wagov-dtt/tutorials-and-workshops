# Dev Container

Ready-to-use development environment for this repo.

## What is here

| File | Purpose |
|------|---------|
| `devcontainer.json` | VS Code / Dev Containers configuration |

## Use it

1. Install Docker.
2. Install the VS Code Dev Containers extension.
3. Open this repo in VS Code.
4. Choose **Dev Containers: Reopen in Container**.
5. Run `just prereqs` inside the container if tools are missing.

The dev container is for local development only. It does not create cloud resources.

## References

- [Dev Containers documentation](https://containers.dev/)
- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
