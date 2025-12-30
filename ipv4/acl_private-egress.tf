resource "aws_network_acl" "private-egress" {
  vpc_id = aws_vpc.main.id

  subnet_ids = concat(
    aws_subnet.private-egress.*.id,
  )

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-private-egress"
    }
  )
}

# SecurityHub
resource "aws_network_acl_rule" "private-egress_ingress_ssh_ipv4" {
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 4022
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "private-egress_ingress_rdp_ipv4" {
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 4389
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}

# HTTP External Requests
resource "aws_network_acl_rule" "private-egress_egress_http_ipv4" {
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 4080
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# HTTPS External Requests
resource "aws_network_acl_rule" "private-egress_egress_https_ipv4" {
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 4443
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Ephemeral Ports for External Requests
resource "aws_network_acl_rule" "private-egress_ingress_ephemeral_ipv4" {
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 4999
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# IMDSv2
resource "aws_network_acl_rule" "private-egress_egress_imds_ipv4" {
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 4980
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "169.254.169.254/32"
  from_port      = 80
  to_port        = 80
}
resource "aws_network_acl_rule" "private-egress_ingress_imds_ipv4" {
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 4981
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "169.254.169.254/32"
  from_port      = 80
  to_port        = 80
}


# RDS
resource "aws_network_acl_rule" "private-egress_ingress_rds_ipv4" {
  count = var.rds_port != null ? length(aws_subnet.private-egress) : 0
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 7000 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = var.rds_port
  to_port        = var.rds_port
}

resource "aws_network_acl_rule" "private-egress_egress_rds_ipv4" {
  count = var.rds_port != null ? length(aws_subnet.private-egress) : 0
  network_acl_id = aws_network_acl.private-egress.id
  rule_number    = 7200 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = var.rds_port
  to_port        = var.rds_port
}
