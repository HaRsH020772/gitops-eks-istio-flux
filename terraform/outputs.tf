output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "region" {
  value = var.region
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "image_reflector_role_arn" {
  description = "IRSA role ARN — annotate the image-reflector-controller ServiceAccount with this in Phase 8"
  value       = module.image_reflector_irsa.iam_role_arn
}

output "ecr_repository_url" {
  description = "Push/pull URI for the demo-app image"
  value       = aws_ecr_repository.demo_app.repository_url
}

output "configure_kubectl" {
  description = "Run this to point kubectl at the new cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
