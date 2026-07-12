# Registry for the demo app. CI (Phase 7) pushes here; Flux image automation
# (Phase 8) polls it via the image-reflector IRSA role.
resource "aws_ecr_repository" "demo_app" {
  name = "demo-app"

  # CI pushes a unique tag per commit; nothing should ever be overwritten.
  image_tag_mutability = "IMMUTABLE"

  # Allow terraform destroy even with images inside (demo cluster).
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

# Keep the registry from accumulating cost: only the 10 newest images.
resource "aws_ecr_lifecycle_policy" "demo_app" {
  repository = aws_ecr_repository.demo_app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "expire all but the 10 newest images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
