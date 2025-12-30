# regional
resource "aws_nat_gateway" "main" {
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
resource "aws_eip" "nat" {
  count = var.nat_type == "zonal" ? local.az_count : 0
  domain = "vpc"

  tags = merge(
	local.tags,
	{
	  Name = "${local.name}-${local.az_name[count.index]}"
	}
  )
}


resource "aws_nat_gateway" "public-egress" {
  count         = var.nat_type == "zonal" ? local.az_count : 0
  availability_mode = "zonal"
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public-egress[count.index].id

  tags = merge(
	local.tags,
	{
	  Name = "${local.name}-nat-${local.az_name[count.index]}"
	}
  )
}
