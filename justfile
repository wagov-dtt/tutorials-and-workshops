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
  eksctl get cluster --name {{CLUSTER}} > /dev/null || eksctl create cluster -f feb2025-workshop/eks-training01-cluster.yaml
  aws kms describe-key --key-id alias/eks/secrets > /dev/null || aws kms create-alias --alias-name alias/eks/secrets --target-key-id $(aws kms create-key --query 'KeyMetadata.KeyId' --output text)
  eksctl utils enable-secrets-encryption --cluster {{CLUSTER}} --key-arn $(aws kms describe-key --key-id alias/eks/secrets --query 'KeyMetadata.Arn' --output text) --region $AWS_REGION # enable kms secrets
  eksctl utils write-kubeconfig --cluster {{CLUSTER}}

# Setup the 2048 game using customize as per the feb workshop
feb2025-workshop:
  kubectl get nodes || just setup-eks
  kubectl apply -k feb2025-workshop/kustomize-envs/training01

template-secret SECRETID: awslogin
  cat feb2025-workshop/secrets-template.yaml | \
  SECRETS=$(aws secretsmanager get-secret-value --secret-id {{SECRETID}} --query SecretString --output text) \
  envsubst