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

TODO: Configure [Managed Identity](https://github.com/gaul/s3proxy/wiki/Storage-backend-examples#aws-s3---managed-identity) proxying of S3 via s3proxy to enable in cluster resources to access S3 without secrets.

# Local development

Similar to above, a close-to-production environment can be stood up locally with [k3d](https://k3d.io/stable/#quick-start) (we use this over minikube as it has better loadbalancer/storage defaults). This configuration also uses the [k3s helm-controller](https://github.com/k3s-io/helm-controller) to enable kustomize to directly deploy [HelmCharts](https://docs.k3s.io/helm#using-the-helm-controller) from [helm-charts.yaml](kustomize/kube-system/helm-charts.yaml) and is much more lightweight than a full argocd or flux config.

```bash
just deploy-local
```

This configures dbs for [postgres](kustomize/everest/postgres.yaml), [mysql](kustomize/everest/mysql.yaml), [mongodb](kustomize/everest/mongodb.yaml) locally and an [S3Proxy](kustomize/everest/s3proxy.yaml) . The deployment can be tweaked for local use just by commenting out resources in the `kustomization.yaml` files, bit more work required to add below capabilities:

- [Percona Everest](ps://docs.percona.com/everest/index.html) preconfigured to use [s3proxy](https://github.com/gaul/s3proxy) endpoint (currently need to create bucket manually at the internal http://s3proxy.everest.svc.cluster.local address)
- [K8up](https://docs.k8up.io/k8up/2.12/how-tos/application-aware-backups.html) preconfigured with s3proxy to demonstrate app aware backups on e.g. a nightly schedule
- Predefine a single node [Elastic](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-elasticsearch.html) template for local testing of elastic workloads

