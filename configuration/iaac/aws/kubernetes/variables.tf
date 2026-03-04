variable "aws_region" {
  type        = string
  description = "AWS region for EKS resources."
  default     = "us-east-1"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
  default     = "in28minutes-cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS control plane."
  default     = "1.29"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Whether the EKS cluster endpoint is publicly accessible."
  default     = true
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Whether the EKS cluster endpoint is privately accessible."
  default     = false
}

variable "enable_cluster_creator_admin_permissions" {
  type        = bool
  description = "Whether the cluster creator gets admin permissions."
  default     = true
}

variable "node_instance_types" {
  type        = list(string)
  description = "Instance types for the managed node group."
  default     = ["t3.micro"]
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of nodes in the managed node group."
  default     = 3
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of nodes in the managed node group."
  default     = 3
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of nodes in the managed node group."
  default     = 5
}

variable "cluster_log_types" {
  type        = list(string)
  description = "Control plane log types to enable."
  default     = ["api", "audit", "authenticator"]
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to EKS resources."
  default     = {
    project = "in28minutes"
  }
}
