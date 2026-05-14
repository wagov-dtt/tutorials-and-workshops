# Glossary

Quick definitions for terms used throughout this repo.

## Local Platform

### kind

Kubernetes in Docker. This repo uses kind for local Kubernetes examples.

**Official docs**: <https://kind.sigs.k8s.io/>

### Helm

Kubernetes package manager. This repo packages Kubernetes examples as Helm charts under `charts/` and deploys them with `helm upgrade --install`.

**Official docs**: <https://helm.sh/docs/>

### Linkerd

A service mesh that provides transparent mTLS, workload identity, and traffic authorization. Local Kubernetes examples use Linkerd as the default in-cluster trust boundary.

**Official docs**: <https://linkerd.io/2/overview/>

### Traefik static config

Traefik can route HTTP traffic from a static file provider. This repo uses that for web/app stacks instead of adding ingress CRDs to each example.

## Kubernetes Concepts

### CSI (Container Storage Interface)

A standard API for storage plugins. Used by the rclone local demo and AWS S3 Files/EFS CSI examples.

### ServiceAccount

An identity for pods. Linkerd turns ServiceAccounts into mesh identities, and EKS Pod Identity uses ServiceAccounts to grant AWS access.

### ClusterIP

The default Kubernetes Service type. Most app origins in this repo are ClusterIP-only and are reached through Traefik or by other approved workloads.

## AWS Concepts

### EKS

AWS managed Kubernetes. See [eksauto/](eksauto/) for the Terraform walkthrough.

### EKS Auto Mode

EKS mode where AWS manages worker capacity and several operational details.

### Pod Identity

An EKS feature that lets pods assume IAM roles without static credentials. Used in [s3-pod-identity/](s3-pod-identity/) and [secrets/](secrets/).

### Secrets Manager

AWS service for storing secrets. The External Secrets demo syncs selected values into Kubernetes.

## Deployment Concepts

### CI with Helm

A simple deployment model where CI runs `helm upgrade --install` against a cluster.

### ArgoCD

A GitOps controller that can reconcile these Helm charts from an orchestration cluster. This repo does not carry ArgoCD application manifests; see [argocd/README.md](argocd/README.md).
