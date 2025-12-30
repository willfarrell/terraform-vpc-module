resource "aws_route_table" "private" {
  count  = 1
  vpc_id = aws_vpc.main.id

  tags = merge(
  local.tags,
  {
    Name = false ? "${local.name}-${local.az_name[count.index]}-private" : "${local.name}-private"
  }
  )
}

resource "aws_route_table_association" "private" {
  count          = local.az_count
  route_table_id = aws_route_table.private[0].id
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_subnet" "private" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  
  availability_zone = local.az_name[count.index]
  assign_ipv6_address_on_creation = true
  enable_dns64 = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  ipv6_native = false
  cidr_block           = cidrsubnet(aws_vpc.main.cidr_block, 8, 4 * 10 + count.index)
  ipv6_cidr_block      = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 4 * 10 + count.index)

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-${local.az_name[count.index]}-private"
    }
  )
}
