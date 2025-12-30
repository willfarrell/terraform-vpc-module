resource "aws_route_table" "public-ingress" {
  count          = var.lb_type != "none" ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-public-ingress"
    }
  )
}

resource "aws_route_table_association" "public-ingress" {
  count          = var.lb_type != "none" ? local.az_count : 0
  route_table_id = aws_route_table.public-ingress[0].id
  subnet_id      = aws_subnet.public-ingress[count.index].id
}

resource "aws_subnet" "public-ingress" {
  count          = var.lb_type != "none" ? local.az_count : 0
  vpc_id            = aws_vpc.main.id
  
  availability_zone = local.az_name[count.index]
  cidr_block           = cidrsubnet(aws_vpc.main.cidr_block, 8, 1 * 10 + count.index)

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-${local.az_name[count.index]}-public-ingress"
    }
  )
}
