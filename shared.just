# Shared settings and helpers — imported by all sub-project justfiles

# List all recipes (default)
default:
    @just --list

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
_k3d:
    @which k3d > /dev/null || (cd "{{ root_dir }}" && mise install)
    k3d cluster create tutorials || k3d cluster start tutorials
    kubectl config use-context k3d-tutorials

[private]
_rclone: _k3d
    helm upgrade --install csi-rclone oci://ghcr.io/veloxpack/charts/csi-driver-rclone --set feature.enableInlineVolume=true
    kubectl apply -f "{{ root_dir }}/rclone/base/deployment.yaml" --server-side

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
