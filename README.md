# tutorials-and-workshops

See our [DevSecOps Induction](https://soc.cyber.wa.gov.au/training/devsecops-induction/) for more structured content, this repo has concepts and templates. Best local environment to play with this repo is [project Bluefin](https://projectbluefin.io/) as primary OS / a VM or [Debian on WSL2 with systemd support](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux)


## IaC intro

Getting started - run below commands to setup your local devcontainer ready to interact with AWS.

```bash
just prereqs
just awslogin # Follow instructions to setup sso account
just setup-eks # Create the training01 cluster in your AWS account
```

Once configured can deploy the 2048 application as per [AWS quickstart](https://docs.aws.amazon.com/eks/latest/userguide/quickstart.html#_deploy_the_2048_game_sample_application) and test out cluster operations. Using [k9s](https://k9scli.io) to explore the cluster is another great way to learn k8s basics.

## S3 Pod Identity Example

Demo of [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) - MySQL backup to S3 with rclone, no credentials in cluster. See [kustomize-s3-pod-identity/](kustomize-s3-pod-identity/) for full details.

```bash
just s3-pod-identity-test    # Full demo: sysbench data → mysqlsh dump → S3 → rclone copy → restore
just s3-pod-identity-cleanup # Removes resources
```

Flow: `MySQL → sysbench test data → mysqlsh dump → S3 backup1/ → rclone server-side copy → S3 backup2/ → mysqlsh restore`

## Justfile Conventions

This repo uses [just](https://github.com/casey/just) as task runner with these patterns:

- `set dotenv-load` + `set export` - `.env` vars available everywhere
- Derived vars at top: `ACCOUNT := \`aws sts ...\`` then use `{{ACCOUNT}}` in recipes
- `-` prefix ignores errors, `@` prefix hides command echo
- `envsubst` for templating K8s manifests with `${VAR}` placeholders
- Private recipes prefixed with `_`

# Local development

Similar to above, a close-to-production environment can be stood up locally with [k3d](https://k3d.io/stable/#quick-start) (we use this over minikube as it has better loadbalancer/storage defaults).

```bash
just deploy-local
```

This configures simple single-node databases for local testing:
- [PostgreSQL](kustomize/databases/postgres.yaml) (official postgres:16)
- [MySQL](kustomize/databases/mysql.yaml) (percona:8.0)
- [MongoDB](kustomize/databases/mongodb.yaml) (official mongo:7)
- [Elasticsearch](kustomize/databases/elasticsearch.yaml) (single-node dev mode, no operator)

# macOS tips

To get working `x86_64` devcontainers locally on macOS below is a quickstart on Apple Silicon with [homebrew](https://brew.sh/) installed.

```bash
# Setup devpod & colima for docker support
brew install colima docker docker-buildx devpod
mkdir -p ~/.docker/cli-plugins
ln -s $(which docker-buildx) ~/.docker/cli-plugins/docker-buildx
# Create a suitably sized vm for dev activities (k3d clusters with local dbs will use 2-3GB of memory)
softwareupdate --install-rosetta --agree-to-license
colima start --cpu 4 --memory 12 --vz-rosetta
devpod provider add docker

# Launch devcontainer with default ide
cd ~/GitHub
gh repo clone wagov-dtt/tutorials-and-workshops
DOCKER_DEFAULT_PLATFORM=linux/amd64 devpod up tutorials-and-workshops
```
