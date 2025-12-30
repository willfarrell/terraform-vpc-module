resource "aws_route_table" "public-egress" {
  count          = var.nat_type == "zonal" ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-public-egress"
    }
  )
}

resource "aws_route_table_association" "public-egress" {
  count          = var.nat_type == "zonal" ? local.az_count : 0
  route_table_id = aws_route_table.public-egress[0].id
  subnet_id      = aws_subnet.public-egress[count.index].id
}

resource "aws_subnet" "public-egress" {
  count             = var.nat_type == "zonal" ? local.az_count : 0
  vpc_id            = aws_vpc.main.id
  
  availability_zone = local.az_name[count.index]
  cidr_block           = cidrsubnet(aws_vpc.main.cidr_block, 8, 0 * 10 + count.index)

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-${local.az_name[count.index]}-public-egress"
    }
  )
}
