data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  azs         = slice(data.aws_availability_zones.available.names, 0, 2)
  bucket_name = lower("${var.project_name}-assets-${data.aws_caller_identity.current.account_id}-${var.aws_region}")

  common_tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
    Week      = "W8"
  }
}

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = local.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}
