set dotenv-load

# Choose a task to run
default:
  just --choose

# Install project tools
prereqs:
  mkdir -p .codeql

# Login to aws using SSO
@awslogin:
  which aws > /dev/null || just prereqs
  # make sure aws logged in
  aws sts get-caller-identity > /dev/null || aws sso login --use-device-code || \
  (echo please run '"aws configure sso --use-device-code"' and add AWS_PROFILE/AWS_REGION to your .env file && exit 1)

# Create an eks cluster for testing (reference https://docs.aws.amazon.com/eks/latest/userguide/quickstart.html)
# Should use terraform/opentofu in future
setup-eks CLUSTER="training01": awslogin
  eksctl get cluster --name {{CLUSTER}} > /dev/null || eksctl create cluster -f eksauto/eks-training01-cluster.yaml
  eksctl update addon -f eksauto/eks-training01-cluster.yaml 
  aws kms describe-key --key-id alias/eks/secrets > /dev/null || aws kms create-alias --alias-name alias/eks/secrets --target-key-id $(aws kms create-key --query 'KeyMetadata.KeyId' --output text)
  eksctl utils enable-secrets-encryption --cluster {{CLUSTER}} --key-arn $(aws kms describe-key --key-id alias/eks/secrets --query 'KeyMetadata.Arn' --output text) --region $AWS_REGION # enable kms secrets
  eksctl utils write-kubeconfig --cluster {{CLUSTER}}


# Install manifests for a given cluster, create the cluster if one is not connected.
deploy CLUSTER="training01":
  eksctl utils write-kubeconfig --cluster {{CLUSTER}} || just setup-eks {{CLUSTER}}
  just install-helm-charts
  kubectl get namespace tutorials-and-workshops || kubectl create namespace tutorials-and-workshops
  # Mount an s3 vol for s3proxy in cluster
  just mount-s3 {{CLUSTER}} s3proxy-data everest
  kubectl apply -k kustomize/overlays/{{CLUSTER}}

# Create a volume in kubernetes using mountpoint for s3 driver
create-s3vol $BUCKET $VOLUME NAMESPACE:
  kubectl get ns "{{NAMESPACE}}"
  cat kustomize/s3volume-template.yaml | envsubst | kubectl apply --namespace {{NAMESPACE}} -f -

# Mount an s3 bucket locally
@mount-s3-bucket BUCKET PATH NAMESPACE:
  aws s3api head-bucket --bucket {{BUCKET}} > /dev/null || aws s3 mb s3://{{BUCKET}} --region $AWS_REGION
  mkdir -p .mnt/{{BUCKET}}/{{PATH}}
  umount .mnt/{{BUCKET}}/{{PATH}} || echo "mountpoint clean"
  # export-credentials workaround for https://github.com/awslabs/mountpoint-s3/issues/433
  $(aws configure export-credentials --format env) && mount-s3  --allow-delete --allow-overwrite {{BUCKET}} --prefix {{PATH}}/ .mnt/{{BUCKET}}/{{PATH}}/
  just create-s3vol {{BUCKET}} {{PATH}} {{NAMESPACE}}


# Mount an s3 bucket from a prefix/path convenient wrapper, if namespace specified create vol in k8s
@mount-s3 PREFIX="training01" PATH="volume01" NAMESPACE="": awslogin
  which mount-s3 > /dev/null || just prereqs
  just mount-s3-bucket "{{PREFIX}}-$(aws sts get-caller-identity --query Account --output text)" "{{PATH}}" "{{NAMESPACE}}"

# Simplest docker hosted k8s cluster
k3d:
  @which k3d > /dev/null || just prereqs
  k3d cluster create --k3s-arg="--disable-helm-controller@all" --k3s-arg="--disable=traefik@all" || k3d cluster start

# deploys local kustomize dir with 3 retries to handle CRD timing
deploy-local +ARGS="--v=3": k3d
  for i in $(seq 4); do kubectl apply -k kustomize/overlays/local --server-side {{ARGS}} && break || sleep 20; done

# deploys local kustomize dir with 3 retries to handle CRD timing
deploy-ducklake +ARGS="--v=3": k3d
  for i in $(seq 4); do kubectl apply -k kustomize-ducklake/overlays/local --server-side {{ARGS}} && break || sleep 20; done

# Runs through a basic test using local k3d hosted just dpostgres/s3
ducklake-test: deploy-ducklake
  uv run ducklake_test.py

rclone-lab +ARGS="--v=3": k3d
  for i in $(seq 4); do kubectl apply -k rclone/kustomize --server-side {{ARGS}} && break || sleep 20; done

# Retreives a secret from AWS Secrets Manager as JSON and saves to kubernetes
install-secret SECRETID $NAMESPACE $NAME: awslogin
  kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE
  cat kustomize/secrets-template.yaml | \
  SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id {{SECRETID}} --query SecretString --output text) \
  envsubst | kubectl apply -f -

# Load test a site with vegeta
vegeta URL:
  which vegeta || brew install vegeta
  echo "GET {{URL}}" | vegeta attack -duration=10s -rate=1000 | vegeta report -type=text

# Run semgrep/CodeQL (SAST) analysis locally and output results to CSV
[working-directory: '.codeql']
codeql: prereqs
    gh extensions install github/gh-codeql
    -semgrep scan --sarif --output semgrep_results.sarif ..
    gh codeql database create --db-cluster --language=go,python,javascript-typescript --threads=0 --source-root=.. --overwrite codeql-db
    gh codeql database analyze --download --format=sarif-latest --threads=0 --output=go_results.sarif codeql-db/go codeql/go-queries
    gh codeql database analyze --download --format=sarif-latest --threads=0 --output=python_results.sarif codeql-db/python codeql/python-queries
    gh codeql database analyze --download --format=sarif-latest --threads=0 --output=javascript_results.sarif codeql-db/javascript codeql/javascript-queries
    uvx --from sarif-tools sarif csv
