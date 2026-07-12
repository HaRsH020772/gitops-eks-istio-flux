terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Partial config: bucket/table names come from backend.hcl (gitignored,
  # account-specific). Generate it from the backend-bootstrap stack's
  # `backend_hcl` output, then:
  #   terraform init -backend-config=backend.hcl
  backend "s3" {}
}
