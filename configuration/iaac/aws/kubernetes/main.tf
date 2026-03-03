# aws --version
# aws eks --region us-east-1 update-kubeconfig --name in28minutes-cluster
# Uses default VPC and Subnet. Create Your Own VPC and Private Subnets for Prod Usage.
# terraform-backend-state-in28minutes-123
# AKIA4AHVNOD7OOO6T4KI


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12"
    }
  }

  backend "s3" {
    bucket = "mybucket" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }
}

resource "aws_default_vpc" "default" {

}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "in28minutes-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"
  cluster_name    = "in28minutes-cluster"
  cluster_version = "1.29"
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false
  subnet_ids      = ["subnet-05e5cd99035c324fc", "subnet-0f0e2ca6e9ab6b120"] #CHANGE
  #subnet_ids = data.aws_subnets.subnets.ids
  vpc_id          = aws_default_vpc.default.id

  #vpc_id         = "vpc-1234556abcdef"

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.micro"]
      max_size       = 5
      desired_size   = 3
      min_size       = 3
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name       = "in28minutes-cluster"
  depends_on = [module.in28minutes-cluster]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = "in28minutes-cluster"
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
