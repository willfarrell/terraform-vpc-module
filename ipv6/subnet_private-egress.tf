resource "aws_route_table" "private-egress" {
  count  = var.nat_type == "zonal" ? local.az_count : 1
  vpc_id = aws_vpc.main.id
  
  dynamic "route" {
    for_each =  var.nat_type == "regional" ? [null] : []
    content {
      ipv6_cidr_block     = "64:ff9b::/96"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }
  
  dynamic "route" {
    for_each =  var.nat_type == "zonal" ? [null] : []
    content {
      ipv6_cidr_block     = "64:ff9b::/96"
      nat_gateway_id = aws_nat_gateway.public-egress[count.index].id
    }
  }
  
  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.main.id
  }
  
  tags = merge(
  local.tags,
  {
    Name = var.nat_type == "zonal" ? "${local.name}-${local.az_name[count.index]}-private-egress" : "${local.name}-private-egress"
  }
  )
}

resource "aws_route_table_association" "private-egress" {
  count          = local.az_count
  route_table_id = var.nat_type == "zonal" ? aws_route_table.private-egress[count.index].id : aws_route_table.private-egress[0].id
  subnet_id      = aws_subnet.private-egress[count.index].id
}

resource "aws_subnet" "private-egress" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  
  availability_zone = local.az_name[count.index]
  assign_ipv6_address_on_creation = true
  enable_dns64 = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  ipv6_native = true
  ipv6_cidr_block      = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 3 * 10 + count.index)
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-${local.az_name[count.index]}-private-egress"
    }
  )
}
