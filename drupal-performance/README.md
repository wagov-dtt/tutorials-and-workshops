Tweaks & tests to a relatively stock drupal on amazon linux env for performance.

```bash
dnf -y install git
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
git clone https://github.com/wagov-dtt/tutorials-and-workshops
cd tutorials-and-workshops/drupal-performance
# Get mountpoint for s3 and restic setup for FS testing
just prereqs
```