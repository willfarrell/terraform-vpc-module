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
    public = "${replace(var.cidr_block, ".0.0/16", "")}.${count.index}.0/25" // LB
    public-egress  = "${replace(var.cidr_block, ".0.0/16", "")}.${count.index}.128/25" // NAT
    private-egress = "${replace(var.cidr_block, ".0.0/16", "")}.${(count.index + 1) * 16}.0/20" // NAT access
    private = "${replace(var.cidr_block, ".0.0/16", "")}.${(count.index + 2) * 16}.0/20"
  }
}

data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  name       = var.name
  tags       = var.default_tags
  cidr_block = var.cidr_block
  az_count = min(
    max(1, var.az_count),
    length(data.aws_availability_zones.available.names)
  )
  az_name      = data.aws_availability_zones.available.names
  public-cidr  = data.null_data_source.cidr.*.outputs.public
  public-egress-cidr  = data.null_data_source.cidr.*.outputs.public-egress
  private-egress-cidr = data.null_data_source.cidr.*.outputs.private-egress
  private-cidr = data.null_data_source.cidr.*.outputs.private
}

