# Restic Backups

Back up GitHub organization dumps to an encrypted [restic](https://restic.net/) repository stored in S3.

## What is here

| Path | Purpose |
|------|---------|
| `justfile` | Recipes for dumping GitHub orgs and running restic |
| `github-dump/` | Generated backup source directory; ignored by git |

## Configure

Set these in `.env` or your shell:

```bash
RESTIC_REPOSITORY=s3:s3.amazonaws.com/YOUR_BUCKET/restic
RESTIC_PASSWORD=change-me
AWS_PROFILE=your-profile
AWS_REGION=ap-southeast-2
```

Use a real secret for `RESTIC_PASSWORD`; it is the encryption key for the backup repository.

## Commands

```bash
just restic/github-dump       # Download GitHub org content locally
just restic/restic-init       # Initialise the restic repository
just restic/restic-backup     # Back up github-dump/
just restic/restic-snapshots  # List snapshots
just restic/backup            # Dump then back up
```

The helper exports short-lived AWS credentials in the same shell line as the `restic` command.

## Cleanup and git hygiene

`github-dump/` is generated and ignored by git. Do not commit dumped repositories, tokens, restic passwords, or local AWS credential files.

## References

- [restic documentation](https://restic.readthedocs.io/)
- [restic S3 backend](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#amazon-s3)
- [AWS CLI configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
