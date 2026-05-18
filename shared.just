# Shared settings and helpers — imported by all sub-project justfiles

default_cluster := "training01"
root_dir := source_directory()

set unstable := true

[private]
_account:
    @aws sts get-caller-identity | jq -r '.Account'

[private]
_bucket:
    @echo "test-$(just _account)"

[private]
_s3files-id:
    @terraform -chdir="{{ root_dir }}/eksauto/terraform" output -raw s3files_file_system_id

[private]
_username:
    @aws sts get-caller-identity | jq -r '.UserId | split(":")[1]'

[private]
_idc-store:
    @aws sso-admin list-instances | jq -r '.Instances[0].IdentityStoreId'

[private]
_idc-arn:
    @aws sso-admin list-instances | jq -r '.Instances[0].InstanceArn'

[private]
_sso-role-arn:
    @ROLE_NAME=$(aws sts get-caller-identity | jq -r '.Arn | split("/")[1]') && \
      aws iam get-role --role-name $ROLE_NAME | jq -r '.Role.Arn'

[private]
_kind:
    @which kind > /dev/null || (cd "{{ root_dir }}" && mise install)
    kind create cluster --name tutorials --config "{{ root_dir }}/kind/config.yaml" || true
    kubectl config use-context kind-tutorials

[private]
_linkerd: _kind
    @which linkerd > /dev/null || (cd "{{ root_dir }}" && mise install)
    if kubectl get namespace linkerd >/dev/null 2>&1; then \
      linkerd check; \
    else \
      linkerd check --pre; \
      kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml; \
      linkerd install --crds | kubectl apply -f -; \
      linkerd install | kubectl apply -f -; \
      linkerd check; \
    fi

[private]
_platform: _kind _linkerd
    @echo "kind + Linkerd platform ready ✓"

[private]
_awslogin:
    @which aws > /dev/null || (cd "{{ root_dir }}" && mise install)
    @aws sts get-caller-identity >/dev/null 2>&1 || aws sso login --use-device-code

[private]
_eks-kubeconfig CLUSTER=default_cluster:
    aws eks update-kubeconfig --name {{ CLUSTER }}
    yq -i '(.users[] | select(.name | test("{{ CLUSTER }}")) | .user.exec.command) = "'$(which aws)'"' ~/.kube/config
    kubectl cluster-info

[private]
_terraform-init:
    -aws s3api create-bucket --bucket tfstate-$(just _account) --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null
    terraform -chdir="{{ root_dir }}/eksauto/terraform" init -backend-config="bucket=tfstate-$(just _account)" -backend-config="region=$AWS_REGION"

[private]
_terraform-validate: _terraform-init
    terraform -chdir="{{ root_dir }}/eksauto/terraform" validate
