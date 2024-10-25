# skaffold-demo
Demo of a few tools in a skaffold repo

## Notes

Use minikube dev container to start

Setup basics:

- Install [homebrew](https://brew.sh)
- Install [skaffold](https://skaffold.dev) with `brew install skaffold`
- Save brew installed stuff with `brew bundle dump` (can install in future all brew stuff with `brew bundle install`)
- Follow [quickstart](https://skaffold.dev/docs/quickstart/)

Enable a CSI storage driver and snapshots (to emulate prod storage)
```bash
# Assuming following skaffold tutorial with 'custom' profile

minikube addons enable volumesnapshots -p custom
minikube addons enable csi-hostpath-driver -p custom
minikube addons disable storage-provisioner -p custom
minikube addons disable default-storageclass -p custom
kubectl patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
