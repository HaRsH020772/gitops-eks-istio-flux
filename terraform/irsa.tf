# IRSA role for Flux's image-reflector-controller (used from Phase 8 on):
# lets it poll ECR for new image tags with no static credentials. Trust is
# scoped to exactly one ServiceAccount: flux-system/image-reflector-controller.
module "image_reflector_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.60"

  role_name = "${var.cluster_name}-image-reflector"

  role_policy_arns = {
    ecr_read = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["flux-system:image-reflector-controller"]
    }
  }

  tags = local.tags
}
