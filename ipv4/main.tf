# TODO You need to manually delete in console
# resource "aws_default_vpc" "default" {
#   force_destroy = true
#   tags = {
#     Name = "Default VPC"
#   }
# }

resource "aws_vpc" "main" {
  cidr_block                       = local.cidr_block
  
  enable_dns_support = true
  enable_dns_hostnames             = true

  tags = merge(
  local.tags,
  {
    Name = local.name
  }
  )
}

# IPv4
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
  local.tags,
  {
    Name = local.name
  }
  )
}

# Override defaults
resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = merge(
  local.tags,
  {
    Name = "${local.name}-default"
  }
  )
}

resource "aws_default_network_acl" "main" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id
  subnet_ids = []
  tags = merge(
  local.tags,
  {
    Name = "${local.name}-default"
  }
  )
}

# TODO You need to manually delete in console
# resource "aws_default_subnet" "default" {
#   count             = local.az_count
#   availability_zone = local.az_name[count.index]
# 
#   force_destroy = true
# }

resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
  local.tags,
  {
    Name = "${local.name}-default"
  }
  )
}
