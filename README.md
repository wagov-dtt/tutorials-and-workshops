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
