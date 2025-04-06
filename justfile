set dotenv-load

# Choose a task to run
default:
  just --choose

# Install project tools
prereqs:
  brew bundle install
  wget "https://s3.amazonaws.com/mountpoint-s3-release/latest/{{arch()}}/mount-s3.deb"
  sudo apt-get -y update && sudo apt-get install -y ./mount-s3.deb
  rm mount-s3.deb

# Login to aws using SSO
@awslogin:
  which aws > /dev/null || just prereqs
  # make sure aws logged in
  aws sts get-caller-identity > /dev/null || aws sso login --use-device-code || \
  (echo please run '"aws configure sso --use-device-code"' and add AWS_PROFILE/AWS_REGION to your .env file && exit 1)

# Create an eks cluster for testing (reference https://docs.aws.amazon.com/eks/latest/userguide/quickstart.html)
setup-eks CLUSTER="training01": awslogin
  eksctl get cluster --name {{CLUSTER}} > /dev/null || eksctl create cluster -f eksauto/eks-training01-cluster.yaml
  eksctl update addon -f eksauto/eks-training01-cluster.yaml 
  aws kms describe-key --key-id alias/eks/secrets > /dev/null || aws kms create-alias --alias-name alias/eks/secrets --target-key-id $(aws kms create-key --query 'KeyMetadata.KeyId' --output text)
  eksctl utils enable-secrets-encryption --cluster {{CLUSTER}} --key-arn $(aws kms describe-key --key-id alias/eks/secrets --query 'KeyMetadata.Arn' --output text) --region $AWS_REGION # enable kms secrets
  eksctl utils write-kubeconfig --cluster {{CLUSTER}}

# Use helm to install percona everest
setup-everest:
  kubectl get namespace everest-system || kubectl create namespace everest-system
  helm repo add percona https://percona.github.io/percona-helm-charts/
  helm upgrade --namespace everest-system --install everest-core percona/everest -f kustomize/helm-values/everest.yaml

# Convenience shell cmds
eks-securitygroups := "eksctl get cluster --name $1 -o json | jq '.[0].ResourcesVpcConfig.SecurityGroupIds + [.[0].ResourcesVpcConfig.ClusterSecu
rityGroupId] | join(\",\")'"
eks-subnets := "eksctl get cluster --name $1 -o json | jq '.[0].ResourcesVpcConfig.SubnetIds | join (\",\")'"

HELM_UPGRADE := "0"
HELM_ACTION := if HELM_UPGRADE == "1" { "upgrade --install" } else { "install" }

helm-install NAME NAMESPACE CHART REPO:
  kubectl get namespace {{NAMESPACE}} || kubectl create namespace {{NAMESPACE}}
  helm repo add {{parent_directory(CHART)}} {{REPO}}
  helm {{HELM_ACTION}} {{NAME}} {{CHART}} --namespace {{NAMESPACE}} -f kustomize/helm-values/{{NAME}}.yaml

# Structure: "NAME": "NAMESPACE CHART REPO"
HELM_INSTALLS := '{
  "traefik": "traefik traefik/traefik https://traefik.github.io/charts",
  "everest-core": "everest-system percona/everest https://percona.github.io/percona-helm-charts",
  "rook-ceph": "rook-ceph rook-release/rook-ceph https://charts.rook.io/release",
  "elastic-operator": "elastic-system elastic/eck-operator https://helm.elastic.co"
}'

# Use helm to enable traefik (gateway), everest (dbs), rook-ceph (storage) and elastic (dbs) in a kubernetes cluster
install-helm-charts +CHARTS="traefik everest-core rook-ceph elastic-operator":
  @-for name in {{CHARTS}}; do just helm-install $name $(echo '{{HELM_INSTALLS}}' | jq -r ".\"$name\""); done

# Install manifests for a given cluster, create the cluster if one is not connected.
deploy CLUSTER="training01":
  eksctl utils write-kubeconfig --cluster {{CLUSTER}} || just setup-eks {{CLUSTER}}
  just install-helm-charts
  kubectl get namespace tutorials-and-workshops || kubectl create namespace tutorials-and-workshops
  kubectl apply -k kustomize/overlays/{{CLUSTER}}

# Mount an s3 bucket locally
@mount-s3-bucket BUCKET PATH:
  aws s3api head-bucket --bucket {{BUCKET}} > /dev/null || aws s3 mb s3://{{BUCKET}} --region $AWS_REGION
  mkdir -p .mnt/{{BUCKET}}/{{PATH}}
  umount .mnt/{{BUCKET}}/{{PATH}} || echo "mountpoint clean"
  # export-credentials workaround for https://github.com/awslabs/mountpoint-s3/issues/433
  $(aws configure export-credentials --format env) && mount-s3  --allow-delete --allow-overwrite {{BUCKET}} --prefix {{PATH}}/ .mnt/{{BUCKET}}/{{PATH}}/

# Mount an s3 bucket from a prefix/path convenient wrapper
@mount-s3 PREFIX="training01" PATH="volume01": awslogin
  which mount-s3 > /dev/null || just prereqs
  just mount-s3-bucket "{{PREFIX}}-$(aws sts get-caller-identity --query Account --output text)" "{{PATH}}"

# Create a volume in kubernetes using mountpoint for s3 driver
create-s3vol $BUCKET $VOLUME NAMESPACE:
  cat kustomize/s3volume-template.yaml | envsubst | kubectl apply --namespace {{NAMESPACE}} -f -

minikube:
  -sudo chown $(whoami) /var/run/docker.sock
  minikube config set memory no-limit
  minikube config set cpus no-limit
  # Setup minikube
  which k9s || just prereqs
  minikube status || minikube start
  minikube addons enable volumesnapshots
  minikube addons enable csi-hostpath-driver
  minikube addons disable storage-provisioner
  minikube addons disable default-storageclass
  kubectl patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'


deploy-local: minikube
  just install-helm-charts
  kubectl get namespace tutorials-and-workshops || kubectl create namespace tutorials-and-workshops
  kubectl apply -k kustomize/overlays/minikube

# Retreives a secret from AWS Secrets Manager as JSON and saves to kubernetes
install-secret SECRETID $NAMESPACE $NAME: awslogin
  kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE
  cat kustomize/secrets-template.yaml | \
  SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id {{SECRETID}} --query SecretString --output text) \
  envsubst | kubectl apply -f -

# Creates requisite secrets from AWS and releases kustomize manifests to a cluster
release-minikube:
  just install-secret trainingsecret01 duckdbui secret01
  kubectl apply -k duckdb-ui/overlays/minikube

# Load test a site with vegeta
vegeta URL:
  which vegeta || brew install vegeta
  echo "GET {{URL}}" | vegeta attack -duration=10s -rate=50000 | vegeta report -type=text