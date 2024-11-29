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

## Notes from last session

Pod identities worked very well, was able to create a bucket/role with terraform and assign it to a service account in cluster to securely access AWS stuff without needing to save any credentials.

### References
- https://eksctl.io/usage/pod-identity-associations/#creating-pod-identity-associations
- https://www.eksworkshop.com/docs/security/amazon-eks-pod-identity/use-pod-identity

This essentially means out of cluster stuff can be managed reasonably from in cluster resources as long as it supports role based access from aws resources. Need to consider how to structure terraform for these use cases.


## Improvements

Work out how to get a single terraform stack to deploy all of the above using [local-exec](https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec) to run the associated eksctl cmds as needed.