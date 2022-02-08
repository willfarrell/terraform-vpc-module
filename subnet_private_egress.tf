
resource "aws_subnet" "private-egress" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private-egress-cidr[count.index]
  availability_zone = local.az_name[count.index]

  tags = merge(
    local.tags,
    {
      Name = "${local.az_name[count.index]}-private-egress-${local.name}"
    }
  )
}

// No NAT
resource "aws_route_table" "private-egress-none" {
  count  = var.nat_type == "none" ? local.az_count : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
  local.tags,
  {
    Name = "private-egress-${local.name}-${local.az_name[count.index]}"
  }
  )
}

resource "aws_route_table_association" "private-egress-none" {
  count          = var.nat_type == "none" ? local.az_count : 0
  subnet_id      = aws_subnet.private-egress[count.index].id
  route_table_id = aws_route_table.private-egress-none[count.index].id
}

// NAT Gateway
resource "aws_route_table" "private-egress-gateway" {
  count  = var.nat_type == "gateway" ? local.az_count : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public-egress[count.index].id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.main.id
  }

  dynamic "route" {
    for_each = aws_vpc_endpoint.main
    content {
      vpc_endpoint_id = route.value.id
    }
  }

  tags = merge(
  local.tags,
  {
    Name = "private-egress-${local.az_name[count.index]}-${local.name}"
  }
  )
}

resource "aws_route_table_association" "private-gateway" {
  count          = var.nat_type == "gateway" ? local.az_count : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private-egress-gateway[count.index].id
}

// NAT Instance
resource "aws_route_table" "private-egress-instance" {
  count  = var.nat_type == "instance" ? local.az_count : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
  local.tags,
  {
    Name = "private-egress-${local.az_name[count.index]}-${local.name}"
  }
  )
}

resource "aws_route_table_association" "private-instance" {
  count          = var.nat_type == "instance" ? local.az_count : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private-egress-instance[count.index].id
}

# ACL
resource "aws_network_acl" "private-egress" {
  vpc_id = aws_vpc.main.id

  subnet_ids = aws_subnet.private-egress.*.id

  tags = merge(
  local.tags,
  {
    Name = "private-egress-${local.name}"
  }
  )
}

# HTTP Internal Requests
resource "aws_network_acl_rule" "private-egress_egress_http_public_ipv4" {
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 4080
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "private-egress_egress_http_public_ipv6" {
  network_acl_id  = aws_network_acl.private-egress.id
  rule_number     = 6080
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 80
  to_port         = 80
}

# HTTPS Internal Requests
resource "aws_network_acl_rule" "private-egress_egress-https-public-ipv4" {
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 4443
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "private-egress_egress-https-public-ipv6" {
  network_acl_id  = aws_network_acl.private-egress.id
  rule_number     = 6443
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

# Ephemeral Ports for Internal Requests
#tfsec:ignore:aws-vpc-no-public-ingress-acl
resource "aws_network_acl_rule" "private-egress_ingress-ephemeral-public-ipv4" {
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 4999
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

#tfsec:ignore:aws-vpc-no-public-ingress-acl
resource "aws_network_acl_rule" "private-egress_ingress-ephemeral-public-ipv6" {
  network_acl_id  = aws_network_acl.private-egress.id
  rule_number     = 6999
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 1024
  to_port         = 65535
}