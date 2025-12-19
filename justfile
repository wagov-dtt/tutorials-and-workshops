set dotenv-load
set export

# Derived variables from environment
ACCOUNT := `aws sts get-caller-identity --query Account --output text 2>/dev/null || echo ""`
BUCKET := "test-" + ACCOUNT

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
# EKS Auto Mode includes envelope encryption by default using AWS KMS
# Pod Identity Agent is built-in to Auto Mode - no addon needed
setup-eks CLUSTER="training01": awslogin
  eksctl get cluster --name {{CLUSTER}} > /dev/null || eksctl create cluster -f eksauto/eks-training01-cluster.yaml
  eksctl update addon -f eksauto/eks-training01-cluster.yaml
  eksctl utils write-kubeconfig --cluster {{CLUSTER}}


# Install manifests for a given cluster, create the cluster if one is not connected.
deploy CLUSTER="training01":
  eksctl utils write-kubeconfig --cluster {{CLUSTER}} || just setup-eks {{CLUSTER}}
  kubectl apply -k kustomize/overlays/{{CLUSTER}}

# Simplest docker hosted k8s cluster (traefik included by default)
k3d:
  @which k3d > /dev/null || just prereqs
  k3d cluster create || k3d cluster start

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

# S3 Pod Identity demo: MySQL + sysbench + backup to S3 + rclone copy + CSI mount
s3-pod-identity-test CLUSTER="training01": awslogin (_s3-clean) (_s3-infra CLUSTER) (_s3-deploy) (_s3-assoc CLUSTER) (_s3-backup) (_s3-copy) (_s3-debug)

_s3-clean:
  -@kubectl delete -k kustomize-s3-pod-identity/jobs 2>/dev/null
  -@kubectl delete -k kustomize-s3-pod-identity 2>/dev/null

# Create AWS infra (bucket, role, CSI driver) - runs before K8s resources
_s3-infra CLUSTER:
  @echo "=== Creating S3 bucket {{BUCKET}} and IAM role ==="
  -aws s3 mb s3://{{BUCKET}} --region $AWS_REGION
  -aws iam create-role --role-name eks-s3-test --assume-role-policy-document \
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"pods.eks.amazonaws.com"},"Action":["sts:AssumeRole","sts:TagSession"]}]}'
  -aws iam attach-role-policy --role-name eks-s3-test --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
  @echo "=== Installing rclone CSI driver ==="
  -helm upgrade --install csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone --namespace veloxpack --create-namespace
  @echo "=== Creating Pod Identity for CSI driver ==="
  -eksctl create podidentityassociation --cluster {{CLUSTER}} --namespace veloxpack \
    --service-account-name csi-rclone-node-sa --role-arn arn:aws:iam::{{ACCOUNT}}:role/eks-s3-test
  @echo "=== Restarting CSI driver to pick up credentials ==="
  kubectl rollout restart ds/csi-rclone-node -n veloxpack
  kubectl rollout status ds/csi-rclone-node -n veloxpack --timeout=60s

# Create Pod Identity association - runs after K8s namespace/SA exist
_s3-assoc CLUSTER:
  kubectl wait --for=jsonpath='{.metadata.name}'=s3-access sa/s3-access -n s3-test --timeout=30s
  @echo "=== Creating Pod Identity association ==="
  -eksctl create podidentityassociation --cluster {{CLUSTER}} --namespace s3-test \
    --service-account-name s3-access --role-arn arn:aws:iam::{{ACCOUNT}}:role/eks-s3-test

_s3-deploy:
  @echo "Using bucket: {{BUCKET}}"
  kubectl kustomize kustomize-s3-pod-identity | envsubst | kubectl apply -f -
  kubectl create configmap s3-config -n s3-test --from-literal=bucket={{BUCKET}} --from-literal=region=$AWS_REGION --dry-run=client -o yaml | kubectl apply -f -
  kubectl wait --for=condition=Available deploy/mysql -n s3-test --timeout=120s
  @echo "=== Running sysbench ==="
  -kubectl wait --for=condition=Complete job/sysbench-prepare -n s3-test --timeout=180s

_s3-backup:
  @echo "=== Backing up MySQL to S3 ==="
  kubectl apply -f kustomize-s3-pod-identity/jobs/backup.yaml
  kubectl wait --for=condition=Complete job/backup-to-s3 -n s3-test --timeout=300s
  kubectl logs job/backup-to-s3 -n s3-test | tail -3

_s3-copy:
  @echo "=== Copying backup1 to backup2 ==="
  kubectl apply -f kustomize-s3-pod-identity/jobs/copy.yaml
  kubectl wait --for=condition=Complete job/rclone-copy -n s3-test --timeout=120s
  kubectl logs job/rclone-copy -n s3-test

# Restore backup to different database name (run after s3-pod-identity-test)
s3-restore:
  @echo "=== Restoring backup to sbtest_restored ==="
  -kubectl delete job restore-from-s3 -n s3-test
  kubectl apply -f kustomize-s3-pod-identity/jobs/restore.yaml
  kubectl wait --for=condition=Complete job/restore-from-s3 -n s3-test --timeout=300s
  kubectl logs job/restore-from-s3 -n s3-test -c mysqlsh-restore | tail -20

_s3-debug:
  @echo "=== Debug pod with S3 CSI mount ==="
  -kubectl wait --for=condition=Ready pod/debug -n s3-test --timeout=120s
  @echo "Run: kubectl exec -it debug -n s3-test -- sh"
  @echo "Then: ls /mnt/s3"

# Cleanup pod identity test resources
s3-pod-identity-cleanup CLUSTER="training01": awslogin
  -kubectl delete -k kustomize-s3-pod-identity/jobs
  -kubectl delete -k kustomize-s3-pod-identity
  -eksctl delete podidentityassociation --cluster {{CLUSTER}} --namespace s3-test --service-account-name s3-access
  -eksctl delete podidentityassociation --cluster {{CLUSTER}} --namespace veloxpack --service-account-name csi-rclone-node-sa
  -aws iam detach-role-policy --role-name eks-s3-test --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
  -aws iam delete-role --role-name eks-s3-test

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
