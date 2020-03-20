# aws/eks env setup for helmfile-infra

## setup EKS

use https://github.com/contino/eks

bhood.tfvars 
```
asg_desired=2
cluster_name="eks-bhood-cluster"
efs_name="bhood-efs"
eks_cluster_version="1.15"
```

```
terraform init
terrafomr apply -var-file="bhood.tfvars"
aws eks update-kubeconfig --name eks-bhood-cluster
```

## install
```
terraform init
terrafomr apply
```
