resource "aws_subnet" "public-egress" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public-egress-cidr[count.index]
  availability_zone = local.az_name[count.index]

  tags = merge(
  local.tags,
  {
    Name = "${local.az_name[count.index]}-public-egress-${local.name}"
  }
  )
}

resource "aws_route_table" "public-egress" {
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
      Name = "public-egress-${local.name}"
    }
  )
}

resource "aws_route_table_association" "public-egress" {
  count          = local.az_count
  subnet_id      = aws_subnet.public-egress[count.index].id
  route_table_id = aws_route_table.public-egress.id
}

# ACL
resource "aws_network_acl" "public-egress" {
  vpc_id = aws_vpc.main.id

  subnet_ids = aws_subnet.public-egress.*.id

  tags = merge(
  local.tags,
  {
    Name = "public-egress-${local.name}"
  }
  )
}

//# HTTP Internal Requests
//resource "aws_network_acl_rule" "public-egress_egress_http_public_ipv4" {
//  network_acl_id = aws_network_acl.public-egress.id
//  rule_number    = 4080
//  egress         = true
//  protocol       = "tcp"
//  rule_action    = "allow"
//  cidr_block     = "0.0.0.0/0"
//  from_port      = 80
//  to_port        = 80
//}
//
//resource "aws_network_acl_rule" "public-egress_egress_http_public_ipv6" {
//  network_acl_id  = aws_network_acl.public-egress.id
//  rule_number     = 6080
//  egress          = true
//  protocol        = "tcp"
//  rule_action     = "allow"
//  ipv6_cidr_block = "::/0"
//  from_port       = 80
//  to_port         = 80
//}

# HTTPS Internal Requests
resource "aws_network_acl_rule" "public-egress_egress-https-public-ipv4" {
  network_acl_id = aws_network_acl.public-egress.id
  rule_number    = 4443
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public-egress_egress-https-public-ipv6" {
  network_acl_id  = aws_network_acl.public-egress.id
  rule_number     = 6443
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

# Ephemeral Ports for Internal Requests
resource "aws_network_acl_rule" "public-egress_ingress-ephemeral-public-ipv4" {
  network_acl_id = aws_network_acl.public-egress.id
  rule_number    = 4999
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public-egress_ingress-ephemeral-public-ipv6" {
  network_acl_id  = aws_network_acl.public-egress.id
  rule_number     = 6999
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 1024
  to_port         = 65535
}


