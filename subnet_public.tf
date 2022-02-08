resource "aws_subnet" "public" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public-cidr[count.index]
  availability_zone = local.az_name[count.index]

  tags = merge(
  local.tags,
  {
    Name = "${local.az_name[count.index]}-public-${local.name}"
  }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.tags,
    {
      Name = "public-${local.name}"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ACL
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id

  #subnet_ids = ["${aws_subnet.public.*.id}"]
  subnet_ids = concat(aws_subnet.public.*.id, aws_subnet.private.*.id)

  tags = merge(
  local.tags,
  {
    Name = "public-${local.name}"
  }
  )
}

# HTTP External Requests
#tfsec:ignore:aws-vpc-no-public-ingress-acl
resource "aws_network_acl_rule" "public_ingress-http-public-ipv4" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 4080
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

#tfsec:ignore:aws-vpc-no-public-ingress-acl
resource "aws_network_acl_rule" "public_ingress-http-public-ipv6" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 6080
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 80
  to_port         = 80
}

# HTTPS External Requests
#tfsec:ignore:aws-vpc-no-public-ingress-acl
resource "aws_network_acl_rule" "public_ingress-https-public-ipv4" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 4443
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

#tfsec:ignore:aws-vpc-no-public-ingress-acl
resource "aws_network_acl_rule" "public_ingress-https-public-ipv6" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 6443
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

# Ephemeral Ports for External Requests
resource "aws_network_acl_rule" "public_egress-ephemeral-public-ipv4" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 4999
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_egress-ephemeral-public-ipv6" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 6999
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 1024
  to_port         = 65535
}
