# local.az_count == length(var.public_subnet_ids)
resource "aws_eip" "nat" {
  count = var.nat_type != "none" ? local.az_count : 0
  domain = "vpc"

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-${local.az_name[count.index]}"
    }
  )
}

