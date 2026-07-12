module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.24"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access = true

  # EKS access entries (API mode): the identity running terraform apply
  # becomes cluster admin.
  enable_cluster_creator_admin_permissions = true

  # OIDC provider for IRSA — consumed by irsa.tf now, and by anything else
  # that needs pod-level AWS permissions later.
  enable_irsa = true

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    metrics-server = {}
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    # Steady baseline for things that shouldn't be interrupted:
    # Flux controllers, istiod, CoreDNS.
    on_demand = {
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.on_demand_node_group.min_size
      max_size     = var.on_demand_node_group.max_size
      desired_size = var.on_demand_node_group.desired_size
    }

    # Cheap burst capacity for app workloads; interruptions are fine there.
    spot = {
      instance_types = var.node_instance_types
      capacity_type  = "SPOT"

      min_size     = var.spot_node_group.min_size
      max_size     = var.spot_node_group.max_size
      desired_size = var.spot_node_group.desired_size
    }
  }

  tags = local.tags
}
