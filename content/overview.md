---
title: "Tutorials and Workshops"
description: "Hands-on DevOps and Kubernetes examples."
weight: 1
icon: "home"
---

Hands-on DevOps and Kubernetes examples. Learn by doing with local k3d labs first, then move to AWS EKS when you are ready.

## Start Here

```bash
just prereqs
just deploy-local
```

This creates a local Kubernetes cluster with databases. No cloud account is needed.

## Local labs

- [Kustomize databases](examples/kustomize.md)
- [rclone CSI local S3 mount](examples/rclone.md)
- [Apps SSO with BookStack, Kanboard, Woodpecker, Keycloak, oauth2-proxy, and Traefik](examples/apps-sso.md)
- [Drupal Hugo/DDEV example](examples/drupal.md)

## AWS labs

- [EKS Auto Mode Terraform](examples/eksauto.md)
- [EKS Pod Identity and AWS S3 Files](examples/s3-pod-identity.md)
- [External Secrets Operator](examples/secrets.md)
- [ArgoCD GitOps](examples/argocd.md)

## Helpful references

- [Getting Started](_index.md)
- [Learning path](learning-path.md)
- [Glossary](glossary.md)
- [Code audit](audit.md)
- [Contributing](contributing.md)
