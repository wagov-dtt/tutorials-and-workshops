# rclone/

Rclone CSI driver examples for mounting S3-compatible storage as Kubernetes volumes.

## Why rclone CSI?

**Mount any cloud storage as a filesystem.** The rclone CSI driver lets pods access S3/GCS/Azure/40+ backends as if they were local directories:

1. **No code changes**: Existing apps that read/write files "just work" with S3
2. **Unified interface**: Same volume mount pattern for S3, GCS, SFTP, etc.
3. **Built-in caching**: VFS cache modes handle read-heavy workloads efficiently

**Why not just use the S3 API directly?** Sometimes you need filesystem semantics - legacy apps, config files, static assets. CSI mounts bridge the gap without refactoring.

## What's Here

| Path | Purpose |
|------|---------|
| `kustomize/` | Full example: rclone-serve (S3 server) + filebrowser + CSI mounts |
| `kustomize/helm/` | Rclone CSI driver helm chart reference |
| `example-rclone.conf` | Sample rclone configuration |

## Quick Start

```bash
just rclone-lab         # Deploy to k3d
kubectl get pods        # Check filebrowser and rclone-serve pods
```

Access filebrowser (after LoadBalancer is ready):
```bash
kubectl get svc filebrowser  # Get external IP
# Open in browser, default login: admin/admin
```

## Learning Goals

- **CSI drivers**: How Container Storage Interface allows custom storage backends
- **rclone as S3 server**: `rclone serve s3` exposes local storage as S3 API
- **CSI volume mounting**: Pods mount S3 buckets as local filesystems via `csi:` volume type
- **VFS caching**: How rclone caches remote files for performance (`vfs-cache-mode: full`)

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  filebrowser │────▶│  CSI Driver  │────▶│ rclone-serve │
│   (3 pods)   │     │   (rclone)   │     │  (S3 API)    │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │
       └──── /srv mount ────┘
```

## Key Concepts

**CSI Volume in Pod spec:**
```yaml
volumes:
  - name: s3-data
    csi:
      driver: rclone.csi.veloxpack.io
      volumeAttributes:
        remote: "s3local"
        remotePath: "mybucket"
```

**Secret for rclone config:**
```yaml
stringData:
  configData: |
    [s3local]
    type = s3
    endpoint = http://rclone-serve:8080
```

## Files to Study

- `kustomize/deployment.yaml` - Shows CSI volume mount pattern
- `kustomize/volumes.yaml` - StorageClass for dynamic provisioning
- `example-rclone.conf` - rclone configuration reference

## See Also

- [kustomize-s3-pod-identity/](../kustomize-s3-pod-identity/) - CSI mounts with real AWS S3 + Pod Identity
