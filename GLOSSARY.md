# Glossary

Short definitions for terms used in this repo, with links to the canonical docs.

## Local platform

### just

Command runner used by this repo for repeatable lab commands such as `just databases/deploy`.

Docs: <https://just.systems/man/en/>

### mise

Tool version manager used to install CLIs from `mise.toml`.

Docs: <https://mise.jdx.dev/>

### kind

Kubernetes in Docker. This repo uses kind for local Kubernetes labs.

Docs: <https://kind.sigs.k8s.io/>

### kubectl

Kubernetes CLI for inspecting and changing cluster resources.

Docs: <https://kubernetes.io/docs/reference/kubectl/>

### Helm

Kubernetes package manager. This repo packages Kubernetes examples as Helm charts under `charts/` and deploys them with `helm upgrade --install`.

Docs: <https://helm.sh/docs/>

### Linkerd

Service mesh that provides transparent mTLS, workload identity, and authorization policy. Local Kubernetes examples use Linkerd as the default in-cluster trust boundary.

Docs: <https://linkerd.io/2/>

### Traefik file/static config

Traefik can route HTTP traffic from a file provider. This repo uses that for local web/app stacks instead of adding ingress CRDs to each example.

Docs: <https://doc.traefik.io/traefik/providers/file/>

## Kubernetes concepts

### ClusterIP

Default Kubernetes Service type. Most app origins in this repo are ClusterIP-only and are reached through Traefik, port-forwarding, or approved in-cluster workloads.

Docs: <https://kubernetes.io/docs/concepts/services-networking/service/>

### CSI (Container Storage Interface)

Standard API for Kubernetes storage plugins. Used by the local rclone demo and AWS S3 Files/EFS CSI examples.

Docs: <https://kubernetes-csi.github.io/docs/>

### NetworkPolicy

Kubernetes resource that describes allowed network traffic for pods when the cluster CNI enforces it.

Docs: <https://kubernetes.io/docs/concepts/services-networking/network-policies/>

### ServiceAccount

Kubernetes identity for pods. Linkerd turns ServiceAccounts into mesh identities, and EKS Pod Identity uses ServiceAccounts to grant AWS access.

Docs: <https://kubernetes.io/docs/concepts/security/service-accounts/>

## AWS concepts

### EKS

AWS-managed Kubernetes. See [eksauto/](eksauto/) for the Terraform walkthrough.

Docs: <https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html>

### EKS Auto Mode

EKS mode where AWS manages worker capacity and several operational details.

Docs: <https://docs.aws.amazon.com/eks/latest/userguide/automode.html>

### EKS Pod Identity

EKS feature that lets pods assume IAM roles without static AWS credentials. Used in [s3-pod-identity/](s3-pod-identity/) and [secrets/](secrets/).

Docs: <https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html>

### AWS Secrets Manager

AWS service for storing and rotating secrets. The External Secrets demo syncs selected values into Kubernetes.

Docs: <https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html>

### AWS S3 Files

AWS feature for mounting S3-backed file systems to EKS through the Amazon EFS CSI driver.

Docs: <https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-files-mounting-eks.html>

## Deployment concepts

### CI with Helm

Deployment model where CI runs `helm upgrade --install` against a target cluster.

### ArgoCD

GitOps controller that can reconcile these Helm charts from an orchestration cluster. This repo does not carry ArgoCD application manifests; see [argocd/README.md](argocd/README.md).

Docs: <https://argo-cd.readthedocs.io/>

### OpenTelemetry

Vendor-neutral telemetry APIs, SDKs, and collector used by the observability lab.

Docs: <https://opentelemetry.io/docs/>
