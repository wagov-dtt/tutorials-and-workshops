# kustomize-ducklake/

DuckLake (DuckDB + S3-compatible storage) local development setup on k3d.

## Why DuckLake?

**DuckDB query performance + cloud storage economics.** DuckLake gives you:

1. **Separation of compute and storage**: Query engine (DuckDB) is stateless, data lives in S3
2. **No data warehouse costs**: Use your existing Postgres for metadata, S3 for cheap storage
3. **Local development parity**: Same architecture locally (rclone-s3) as production (real S3)

**Why not just use Postgres/MySQL directly?** For OLAP workloads (aggregations, analytics), columnar formats (Parquet) on object storage are 10-100x faster and cheaper than row-based databases.

## What's Here

| Path | Purpose |
|------|---------|
| `base/` | Namespace definition |
| `databases/` | Postgres (metadata catalog) + rclone-s3 (S3-compatible object store) |
| `overlays/local/` | k3d deployment entrypoint |

## Quick Start

```bash
just deploy-ducklake    # Deploy Postgres + rclone-s3 to k3d
just ducklake-test      # Run full test (loads NY Taxi data, runs queries)
```

The test script (`ducklake_test.py`) will:
1. Wait for Postgres to be ready
2. Set up port forwards automatically
3. Create an S3 bucket via rclone
4. Load sample data from NY Taxi dataset
5. Run aggregation queries

## Learning Goals

- **DuckLake architecture**: DuckDB as query engine + Postgres for metadata + S3 for data storage
- **Local S3 mocking**: rclone-s3 provides an S3-compatible API for local development
- **Port forwarding pattern**: Test script shows how to connect local tools to k8s services

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   DuckDB    │────▶│  Postgres   │     │  rclone-s3  │
│  (client)   │     │  (catalog)  │     │ (S3 storage)│
└─────────────┘     └─────────────┘     └─────────────┘
      │                                        ▲
      └────────────────────────────────────────┘
                    (parquet files)
```

## Exploring

After `just deploy-ducklake`:
```bash
kubectl get pods -n databases
kubectl port-forward svc/rclone-s3 8080:80 -n databases  # Access S3 API
kubectl port-forward svc/postgres 5432:5432 -n databases  # Access Postgres
```

## Files to Study

- `ducklake_test.py` (root) - Python script demonstrating DuckLake usage
- `databases/rclone-s3.yaml` - S3-compatible server using rclone
- `databases/postgres.yaml` - Postgres for DuckLake metadata
