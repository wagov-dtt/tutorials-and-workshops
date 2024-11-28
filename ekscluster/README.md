## EKS cluster notes

```bash
# Creating a basic cluster
aws sso configure
export AWS_PROFILE=...
export AWS_REGION=ap-southeast-2
aws sso login
eksctl create cluster --config-file ekscluster/eks-basic.yaml 
```
Steps to take after creating basic cluster (i.e. once kubectl available)

- Install eks as per above guidance
- Install a key value store on cluster with default storage (above will use EBS)
- Create an S3 bucket for large/backup storage
- Install juicefs https://juicefs.com/docs/csi/guide/cache and back it with the in cluster key store and S3 bucket
- Configure namespace defaults + ingress defaults
- Test deploying stuff to it via skaffold/helm
- Test storage management with juicefs cli in cluster and volume snapshots
- Test destroying a cluster and restoring from S3
- Test node failure and node replacement