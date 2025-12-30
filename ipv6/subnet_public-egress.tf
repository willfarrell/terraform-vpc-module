resource "aws_route_table" "public-egress" {
  count          = var.nat_type == "zonal" ? 1 : 0
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.main.id
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
  assign_ipv6_address_on_creation = true
  enable_dns64 = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  ipv6_native = true
  ipv6_cidr_block      = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0 * 10 + count.index)

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-${local.az_name[count.index]}-public-egress"
    }
  )
}
