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
resource "aws_network_acl_rule" "private-egress_ingress_ssh_ipv6" {
  network_acl_id  = aws_network_acl.private-egress.id
  rule_number     = 6022
  egress          = false
  protocol        = "tcp"
  rule_action     = "deny"
  ipv6_cidr_block = "::/0"
  from_port       = 22
  to_port         = 22
}

resource "aws_network_acl_rule" "private-egress_ingress_rdp_ipv6" {
  network_acl_id  = aws_network_acl.private-egress.id
  rule_number     = 6389
  egress          = false
  protocol        = "tcp"
  rule_action     = "deny"
  ipv6_cidr_block = "::/0"
  from_port       = 3389
  to_port         = 3389
}

# HTTP External Requests
resource "aws_network_acl_rule" "private-egress_egress_http_ipv6" {
  network_acl_id  = aws_network_acl.private-egress.id
  rule_number     = 6080
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 80
  to_port         = 80
}

# HTTPS External Requests
resource "aws_network_acl_rule" "private-egress_egress_https_ipv6" {
  network_acl_id  = aws_network_acl.private-egress.id
  rule_number     = 6443
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

# Ephemeral Ports for External Requests
resource "aws_network_acl_rule" "private-egress_ingress_ephemeral_ipv6" {
  network_acl_id  = aws_network_acl.private-egress.id
  rule_number     = 6999
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 1024
  to_port         = 65535
}

# IMDSv2 - skip IPv6 not required. 64:ff9b::a00:2af5

# RDS
resource "aws_network_acl_rule" "private-egress_ingress_rds_ipv6" {
  count = var.rds_port != null ? length(aws_subnet.private-egress) : 0
  network_acl_id  = aws_network_acl.private-egress.id
  rule_number     = 7100 + count.index
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block     = aws_subnet.private[count.index].ipv6_cidr_block
  from_port       = var.rds_port
  to_port         = var.rds_port
}

resource "aws_network_acl_rule" "private-egress_egress_rds_ipv6" {
  count = var.rds_port != null ? length(aws_subnet.private-egress) : 0
  network_acl_id  = aws_network_acl.private-egress.id
  rule_number     = 7300 + count.index
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block     = aws_subnet.private[count.index].ipv6_cidr_block
  from_port       = var.rds_port
  to_port         = var.rds_port
}

