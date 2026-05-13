# rclone/

> Local rclone CSI demo on kind, packaged as `charts/rclone-demo`.

## Quick Start

```bash
just rclone/rclone-test
kubectl -n rclone port-forward svc/filebrowser 8080:80
```

Open <http://localhost:8080>.

## What this teaches

- Installing a third-party CSI driver with Helm
- Deploying demo workloads from a local Helm chart
- Mounting S3-compatible storage into a pod
- Using Linkerd policy to restrict filebrowser -> rclone traffic

## What to Study

| Path | Purpose |
|------|---------|
| `../charts/rclone-demo/templates/deployment.yaml` | rclone S3 server and filebrowser workload |
| `../charts/rclone-demo/templates/volumes.yaml` | StorageClass/PVC example |
| `../charts/rclone-demo/templates/linkerd-policy.yaml` | Mesh authorization for the demo |

## Cleanup

```bash
just rclone/clean
```
