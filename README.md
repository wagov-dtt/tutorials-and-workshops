# tutorials-and-workshops

Current focus is skaffold for devs, and talos k8s for operations.

## Feb workshop on infrastructure as code

Getting started - run below commands to setup your local devcontainer ready to interact with AWS.

```bash
just prereqs
just awslogin # Follow instructions to setup sso account
just setup-eks # Create the training01 cluster in your AWS account
```

Once configured can deploy the 2048 application as per [AWS quickstart](https://docs.aws.amazon.com/eks/latest/userguide/quickstart.html#_deploy_the_2048_game_sample_application) and test out cluster operations. Using [k9s](https://k9scli.io) to explore the cluster is another great way to learn k8s basics.

## 14 March continuation

Looked at secrets and the below setup - configured a minikube release that pulled data from secrets manager as the interactive user of a justfile in a repo, without exposing secrets outside cluster.

![alt text](image.png)

Refer to [justfile](./justfile) for the below steps which setup a minikube cluster in your devcontainer/local vm and then deploys a secret and some resources to it from the duckdb-ui dir (actually using a traefik debug container coz of port fwding gotchas). Traefik [whoami](https://github.com/traefik/whoami) container has a very nice /api?env=true debug call that prints useful OS/env/HTTP header info that can be used to validate configs/secrets.

## Notes

Use minikube dev container to start

Setup basics:

- Install [homebrew](https://brew.sh)
- Install [skaffold](https://skaffold.dev) with `brew install skaffold`
- Save brew installed stuff with `brew bundle dump` (can install in future all brew stuff with `brew bundle install`)
- Follow [quickstart](https://skaffold.dev/docs/quickstart/)

```bash
# Devcontainer config should already have done this.
source install-tools.sh
```

Enable a CSI storage driver and snapshots (to emulate prod storage)
[minkube volume snapshots](https://minikube.sigs.k8s.io/docs/tutorials/volume_snapshots_and_csi/)

```bash
# Minikube inital setup with sensible addons
minikube start --addons volumesnapshots --addons csi-hostpath-driver --cpus no-limit --memory no-limit
minikube addons disable storage-provisioner
minikube addons disable default-storageclass
kubectl patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl apply -f https://projectcontour.io/quickstart/contour-gateway-provisioner.yaml
kubectl apply -f - <<EOF
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: contour
spec:
  controllerName: projectcontour.io/gateway-controller
EOF
kubectl apply -f - <<EOF
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: contour
  namespace: projectcontour
spec:
  gatewayClassName: contour
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
EOF
kubectl apply -f https://raw.githubusercontent.com/projectcontour/contour/main/examples/example-workload/gatewayapi/kuard/kuard.yaml
kubectl -n projectcontour port-forward service/envoy-contour 8888:80
skaffold config set --global local-cluster true
eval $(minikube docker-env)
```

