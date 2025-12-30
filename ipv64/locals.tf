data "aws_availability_zones" "available" {
  # no local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# data "null_data_source" "cidr" {
#   count = local.az_count
#   inputs = {
#     public-egress  = "${replace(var.cidr_block, ".0.0/16", "")}.${count.index}.0/24"
#     private-egress = "${replace(var.cidr_block, ".0.0/16", "")}.${(count.index + 1) * 16}.0/20"
#     private = "${replace(var.cidr_block, ".0.0/16", "")}.${(count.index + 2) * 16}.0/20"
#   }
# }
# 
# resource "terraform_data" "cidr" {
#   count = local.az_count
#   input = {
#     public-egress  = "${replace(var.cidr_block, ".0.0/16", "")}.${count.index}.0/24"
#     private-egress = "${replace(var.cidr_block, ".0.0/16", "")}.${(count.index + 1) * 16}.0/20"
#     private = "${replace(var.cidr_block, ".0.0/16", "")}.${(count.index + 2) * 16}.0/20"
#   }
# }

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  env     = terraform.workspace
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
  
  name       = var.name
  tags       = merge(
    {
      TerraformModule = "@willfarrell/terraform-vpc-module/dual"
    }, 
    var.tags
  )
  cidr_block = var.cidr_block
  az_count = min(
    max(1, var.az_count),
    length(data.aws_availability_zones.available.names)
  )
  az_name      = data.aws_availability_zones.available.names
  # public-egress_cidr  = terraform_data.cidr.*.output.public-egress
  # private-egress_cidr = terraform_data.cidr.*.output.private-egress
  # private_cidr = terraform_data.cidr.*.output.private
}

