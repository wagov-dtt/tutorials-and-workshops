# rclone/

Local rclone CSI demo on kind, packaged as `charts/rclone-demo`.

This is a local teaching lab. The EKS S3 mount path uses AWS S3 Files instead; see [s3-pod-identity/](../s3-pod-identity/).

## Quick start

```bash
just rclone/deploy
just rclone/smoke
kubectl -n rclone port-forward svc/filebrowser 8080:80
```

Open <http://localhost:8080>.

## What you learn

- Installing a third-party CSI driver with Helm
- Mounting S3-compatible storage into a pod
- Deploying demo workloads from a local Helm chart
- Restricting filebrowser-to-rclone traffic with Linkerd policy

## What to study

| Path | Purpose |
|------|---------|
| `../charts/rclone-demo/templates/deployment.yaml` | rclone S3 server and filebrowser workload |
| `../charts/rclone-demo/templates/volumes.yaml` | StorageClass and PVC example |
| `../charts/rclone-demo/templates/linkerd-policy.yaml` | Mesh authorization for the demo |
| `../charts/rclone-demo/templates/networkpolicy.yaml` | CNI NetworkPolicy teaching baseline |

## Useful commands

```bash
kubectl -n rclone get pod,pvc,svc
kubectl -n rclone logs deploy/rclone
helm template rclone-demo ../charts/rclone-demo
```

## Cleanup

```bash
just rclone/clean
```

## References

- [rclone docs](https://rclone.org/docs/)
- [rclone S3 backend](https://rclone.org/s3/)
- [Kubernetes CSI docs](https://kubernetes-csi.github.io/docs/)
