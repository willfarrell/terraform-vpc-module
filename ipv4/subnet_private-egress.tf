resource "aws_route_table" "private-egress" {
  count  = var.nat_type == "zonal" ? local.az_count : 1
  vpc_id = aws_vpc.main.id
  
  dynamic "route" {
    for_each =  var.nat_type == "regional" ? [null] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }
  
  dynamic "route" {
    for_each =  var.nat_type == "zonal" ? [null] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.public[count.index].id
    }
  }
  
  tags = merge(
  local.tags,
  {
    Name = var.nat_type == "zonal" ? "${local.name}-${local.az_name[count.index]}-private-egress" : "${local.name}-private-egress"
  }
  )
}

resource "aws_route_table_association" "private-egress" {
  count  = local.az_count
  route_table_id = var.nat_type == "zonal" ? aws_route_table.private-egress[count.index].id : aws_route_table.private-egress[0].id
  subnet_id      = aws_subnet.private-egress[count.index].id
}

resource "aws_subnet" "private-egress" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  
  availability_zone = local.az_name[count.index]
  cidr_block           = cidrsubnet(aws_vpc.main.cidr_block, 8, 3 * 10 + count.index)

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-${local.az_name[count.index]}-private-egress"
    }
  )
}
