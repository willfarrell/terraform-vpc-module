resource "aws_route_table" "private" {
  count  = var.nat_type == "none" ? local.az_count : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
  local.tags,
  {
    Name = "private-${local.name}-${local.az_name[count.index]}"
  }
  )
}

resource "aws_route_table_association" "private" {
  count          = var.nat_type == "none" ? local.az_count : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_subnet" "private" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_cidr[count.index]
  availability_zone = local.az_name[count.index]

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-${local.az_name[count.index]}-private"
    }
  )
}

# route_table is handled by the NAT
