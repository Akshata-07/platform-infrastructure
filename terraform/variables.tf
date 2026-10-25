
variable "aws_region" {
  description = "AWS region for project infrastructure"
  type        = string
  default     = "ap-south-1"
}


variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "devops-portfolio-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.37"
}

variable "cluster_api_allowed_cidr" {
  description = "Public IP CIDR allowed to access the EKS API"
  type        = string
  default     = "103.197.227.96/32"
}
