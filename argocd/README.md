# ArgoCD

This repo packages Kubernetes examples as Helm charts. You can deploy them directly from CI with `helm upgrade --install`, or reconcile the same charts from an orchestration cluster running ArgoCD.

The repo intentionally does not carry ArgoCD `Application` or `ApplicationSet` manifests. If you add them later, pin a branch, tag, or commit instead of tracking a moving revision.

## Minimal shape

```yaml
source:
  repoURL: https://github.com/wagov-dtt/tutorials-and-workshops
  targetRevision: <tag-or-commit>
  path: charts/databases
```

## References

- [ArgoCD documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Helm guide](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
- [AWS-managed ArgoCD on EKS](https://docs.aws.amazon.com/eks/latest/userguide/argocd.html)
