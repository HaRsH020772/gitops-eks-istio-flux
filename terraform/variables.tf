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
  description = "Instance types for both managed node groups"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "on_demand_node_group" {
  description = "Sizing for the ON_DEMAND node group (steady baseline: Flux, Istio control plane)"
  type = object({
    min_size     = number
    max_size     = number
    desired_size = number
  })
  default = {
    min_size     = 1
    max_size     = 2
    desired_size = 1
  }
}

variable "spot_node_group" {
  description = "Sizing for the SPOT node group (cheap burst capacity for workloads)"
  type = object({
    min_size     = number
    max_size     = number
    desired_size = number
  })
  default = {
    min_size     = 1
    max_size     = 3
    desired_size = 1
  }
}
