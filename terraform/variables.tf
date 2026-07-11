variable "region" {
  description = "AWS region for the cluster"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "weekend-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.35"
}

variable "node_instance_types" {
  description = "Instance types for the spot node group (diversity improves spot availability)"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_desired_size" {
  type    = number
  default = 2
}
