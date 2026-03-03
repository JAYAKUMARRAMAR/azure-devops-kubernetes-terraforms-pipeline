# aws --version
# aws eks --region us-east-1 update-kubeconfig --name in28minutes-cluster
# Uses default VPC and Subnet. Create Your Own VPC and Private Subnets for Prod Usage.
# terraform-backend-state-in28minutes-123
# AKIA4AHVNOD7OOO6T4KI


terraform {
  backend "s3" {
    bucket = "mybucket" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, < 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12"
    }
  }
}

resource "aws_default_vpc" "default" {

}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}    

module "in28minutes-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 19.0"
  cluster_name    = "in28minutes-cluster-1"
  cluster_version = "1.29"
  create_kms_key               = true
  create_cloudwatch_log_group  = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = null
  }
  vpc_id          = aws_default_vpc.default.id
  subnet_ids      = data.aws_subnets.subnets.ids
  #vpc_id         = "vpc-1234556abcdef"

  eks_managed_node_groups = {
    default = {
      instance_types  = ["t2.micro"]
      max_capacity    = 5
      desired_capacity = 3
      min_capacity    = 3
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name       = module.in28minutes-cluster.cluster_name
  depends_on = [module.in28minutes-cluster]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.in28minutes-cluster.cluster_name
  depends_on = [module.in28minutes-cluster]
}


# We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
# ServiceAccount needs permissions to create deployments 
# and services in default namespace
resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}

# Needed to set the default region
provider "aws" {
  region  = "us-east-1"
}