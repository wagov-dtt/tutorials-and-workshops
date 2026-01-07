# rclone/

> Mount S3-compatible storage as Kubernetes volumes using the rclone CSI driver.

## Why rclone CSI?

The rclone CSI driver lets pods access S3, GCS, Azure, and 40+ other backends as if they were local directories:

1. **No code changes**: Existing apps that read/write files work with S3 without modification
2. **Unified interface**: Same volume mount pattern for S3, GCS, SFTP, and other backends
3. **Built-in caching**: VFS cache modes handle read-heavy workloads efficiently

**When to use this**: When your application needs filesystem semantics—legacy apps, config files, static assets. CSI mounts bridge the gap without refactoring code to use S3 APIs directly.

## Quick Start

```bash
just rclone-test        # Deploy to k3d and verify CSI mount
kubectl get pods        # Check filebrowser and rclone-serve pods
```

Access filebrowser (after LoadBalancer is ready):

```bash
kubectl get svc filebrowser  # Get external IP
# Open in browser, default login: admin/admin
```

## What's Here

| Path | Purpose |
|------|---------|
| `base/` | Full example: rclone-serve (S3 server), filebrowser, and CSI mounts |
| `example-rclone.conf` | Sample rclone configuration |

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  filebrowser │────▶│  CSI Driver  │────▶│ rclone-serve │
│   (3 pods)   │     │   (rclone)   │     │  (S3 API)    │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │
       └──── /srv mount ────┘
```

## Learning Goals

- **CSI drivers**: How Container Storage Interface allows custom storage backends in Kubernetes
- **rclone as S3 server**: `rclone serve s3` exposes local storage as an S3-compatible API
- **CSI volume mounting**: Pods mount S3 buckets as local filesystems via `csi:` volume type
- **VFS caching**: How rclone caches remote files for performance (`vfs-cache-mode: full`)

## Key Concepts

**CSI Volume in Pod spec**:

```yaml
volumes:
  - name: s3-data
    csi:
      driver: rclone.csi.veloxpack.io
      volumeAttributes:
        remote: "s3local"
        remotePath: "mybucket"
```

**Secret for rclone config**:

```yaml
stringData:
  configData: |
    [s3local]
    type = s3
    endpoint = http://rclone-serve:8080
```

## Files to Study

- `base/deployment.yaml` - Shows CSI volume mount pattern
- `base/volumes.yaml` - StorageClass for dynamic provisioning
- `example-rclone.conf` - rclone configuration reference

## See Also

- [LEARNING_PATH.md](../LEARNING_PATH.md#13-csi-volumes-with-rclone) - Step-by-step walkthrough
- [GLOSSARY.md](../GLOSSARY.md#csi-container-storage-interface) - CSI definition
- [GLOSSARY.md](../GLOSSARY.md#rclone) - rclone definition
- [s3-pod-identity/](../s3-pod-identity/) - CSI mounts with real AWS S3 and Pod Identity
- [rclone documentation](https://rclone.org/) - Official rclone docs
