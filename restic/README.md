# Restic Backups

Back up GitHub organization dumps to an encrypted restic repository.

## What is here

- `justfile` - recipes for dumping GitHub orgs and running restic.
- `github-dump/` - generated backup source directory; ignored by git.

## Configure

Set these in `.env` or your shell:

```bash
RESTIC_REPOSITORY=s3:s3.amazonaws.com/YOUR_BUCKET/restic
RESTIC_PASSWORD=change-me
AWS_PROFILE=your-profile
AWS_REGION=ap-southeast-2
```

## Commands

```bash
just restic/github-dump       # Download GitHub org content locally
just restic/restic-init       # Initialise the restic repository
just restic/restic-backup     # Back up github-dump/
just restic/restic-snapshots  # List snapshots
just restic/backup            # Dump then back up
```

The restic helper exports short-lived AWS credentials in the same shell line as the `restic` command.
