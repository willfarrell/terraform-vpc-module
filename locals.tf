data "aws_availability_zones" "available" {
  # no local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "null_data_source" "cidr" {
  count = local.az_count
  inputs = {
    public  = "${replace(var.cidr_block, ".0.0/16", "")}.${count.index}.0/24"
    private = "${replace(var.cidr_block, ".0.0/16", "")}.${(count.index + 1) * 16}.0/20"
    intra = "${replace(var.cidr_block, ".0.0/16", "")}.${(count.index + 2) * 16}.0/20"
  }
}

data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

module "defaults" {
  source = "git@github.com:willfarrell/terraform-defaults?ref=v0.1.0"
  name   = var.name
  tags   = var.default_tags
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_caller_identity.current.user_id
  name       = module.defaults.name
  tags       = module.defaults.tags
  cidr_block = var.cidr_block
  az_count = min(
    max(1, var.az_count),
    length(data.aws_availability_zones.available.names)
  )
  az_name      = data.aws_availability_zones.available.names
  public_cidr  = data.null_data_source.cidr.*.outputs.public
  private_cidr = data.null_data_source.cidr.*.outputs.private
  intra_cidr = data.null_data_source.cidr.*.outputs.intra
}

