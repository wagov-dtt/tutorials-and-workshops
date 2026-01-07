# ducklake/

> DuckDB analytics with S3-compatible storage for local development on k3d.

## Why DuckLake?

DuckLake combines DuckDB's query performance with cloud storage economics:

1. **Separation of compute and storage**: The query engine (DuckDB) is stateless; data lives in S3
2. **No data warehouse costs**: Use your existing Postgres for metadata, S3 for cheap storage
3. **Local development parity**: Same architecture locally (rclone-s3) as production (real S3)

**When to use this pattern**: For analytics workloads—aggregations, reporting, business intelligence. Columnar formats like Parquet on object storage are 10-100x faster and cheaper than row-based databases for these use cases.

## Quick Start

```bash
just ducklake-test      # Deploy and run full test
```

The test script (`ducklake_test.py`) will:
1. Wait for Postgres to be ready
2. Set up port forwards automatically
3. Create an S3 bucket via rclone
4. Load sample data from the NY Taxi dataset
5. Run aggregation queries

## What's Here

| Path | Purpose |
|------|---------|
| `base/` | Namespace definition |
| `databases/` | Postgres (metadata catalog) and rclone-s3 (S3-compatible object store) |
| `overlays/local/` | k3d deployment entrypoint |

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

## Learning Goals

- **DuckLake architecture**: DuckDB as query engine, Postgres for metadata, S3 for data storage
- **Local S3 mocking**: rclone-s3 provides an S3-compatible API for local development
- **Port forwarding pattern**: The test script shows how to connect local tools to Kubernetes services

## Exploring

After running `just ducklake-test`:

```bash
kubectl get pods -n databases
kubectl port-forward svc/rclone-s3 8080:80 -n databases   # Access S3 API
kubectl port-forward svc/postgres 5432:5432 -n databases  # Access Postgres
```

## Files to Study

- `ducklake_test.py` (in repo root) - Python script demonstrating DuckLake usage
- `databases/rclone-s3.yaml` - S3-compatible server using rclone
- `databases/postgres.yaml` - Postgres for DuckLake metadata

## See Also

- [LEARNING_PATH.md](../LEARNING_PATH.md#12-ducklake-analytics) - Step-by-step walkthrough
- [GLOSSARY.md](../GLOSSARY.md#duckdb) - DuckDB definition
- [GLOSSARY.md](../GLOSSARY.md#olap-online-analytical-processing) - OLAP explanation
- [rclone/](../rclone/) - More rclone CSI examples
- [DuckDB documentation](https://duckdb.org/) - Official DuckDB docs
