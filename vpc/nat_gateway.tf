resource "aws_route_table" "private-regional" {
  count  = var.nat_type == "regional" ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.regional[0].id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.main.id
  }

  tags = merge(
    local.tags,
    {
      Name = "private-regional-${local.name}"
    }
  )
}

resource "aws_nat_gateway" "regional" {
  count         = var.nat_type == "regional" ? 1 : 0
  vpc_id            = aws_vpc.main.id
  availability_mode = "regional"
  
  tags = merge(
  local.tags,
  {
    Name = "${local.name}-nat"
  }
  )
}

# zonal
resource "aws_route_table" "private-zonal" {
  count  = var.nat_type == "zonal" ? local.az_count : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.zonal[count.index].id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.main.id
  }

  tags = merge(
    local.tags,
    {
      Name = "private-zonal-${local.name}-${local.az_name[count.index]}"
    }
  )
}

resource "aws_route_table_association" "private-zonal" {
  count          = var.nat_type == "zonal" ? local.az_count : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private-zonal[count.index].id
}

# gateway
resource "aws_nat_gateway" "zonal" {
  count         = var.nat_type == "zonal" ? local.az_count : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-nat-${local.az_name[count.index]}"
    }
  )
}

