resource "aws_vpc" "main" {
  cidr_block                       = local.cidr_block
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

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

# IPv6
resource "aws_egress_only_internet_gateway" "main" {
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

  tags = merge(
  local.tags,
  {
    Name = "${local.name}-default"
  }
  )
}

resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
  local.tags,
  {
    Name = "${local.name}-default"
  }
  )
}
