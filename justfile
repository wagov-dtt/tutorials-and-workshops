set dotenv-load

# Choose a task to run
default:
  just --choose

# Install project tools
prereqs:
  brew bundle install

# Login to aws using SSO
awslogin:
  which aws || just prereqs
  aws sts get-caller-identity > /dev/null || aws sso login --use-device-code || echo please run '"aws configure sso --use-device-code"' and add AWS_PROFILE/AWS_REGION to your .env file # make sure aws logged in

# Create an eks cluster for testing (reference https://docs.aws.amazon.com/eks/latest/userguide/quickstart.html)
setup-eks CLUSTER="training01": awslogin
  eksctl get cluster --name {{CLUSTER}} > /dev/null || eksctl create cluster -f eksauto/eks-training01-cluster.yaml
  aws kms describe-key --key-id alias/eks/secrets > /dev/null || aws kms create-alias --alias-name alias/eks/secrets --target-key-id $(aws kms create-key --query 'KeyMetadata.KeyId' --output text)
  eksctl utils enable-secrets-encryption --cluster {{CLUSTER}} --key-arn $(aws kms describe-key --key-id alias/eks/secrets --query 'KeyMetadata.Arn' --output text) --region $AWS_REGION # enable kms secrets
  eksctl utils write-kubeconfig --cluster {{CLUSTER}}

# Install manifests for a given cluster, create the cluster if one is not connected.
deploy CLUSTER:
  eksctl utils write-kubeconfig --cluster {{CLUSTER}} || just setup-eks {{CLUSTER}}
  kubectl get namespace traefik || kubectl create namespace traefik
  helm status traefik --namespace traefik || helm upgrade --namespace traefik --install traefik traefik/traefik -f kustomize/helm-values/traefik.yaml 
  kubectl get namespace tutorials-and-workshops || kubectl create namespace tutorials-and-workshops
  kubectl apply -k kustomize/overlays/{{CLUSTER}}

# Force upgrade traefik including reapply of helm-values/traefik.yaml
upgrade-traefik CLUSTER:
  eksctl utils write-kubeconfig --cluster {{CLUSTER}} || just setup-eks {{CLUSTER}}
  helm upgrade --namespace traefik --install traefik traefik/traefik -f kustomize/helm-values/traefik.yaml

minikube:
  minikube config set memory no-limit
  minikube config set cpus no-limit
  # Setup minikube
  which k9s || just prereqs
  minikube status || minikube start # if kube configured use that cluster, otherwise start minikube

deploy-local: minikube
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