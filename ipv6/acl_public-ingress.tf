resource "aws_network_acl" "public-ingress" {
  count          = var.lb_type != "none" ? 1 : 0
  vpc_id = aws_vpc.main.id

  subnet_ids = concat(
    aws_subnet.public-ingress.*.id,
  )

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-public-ingress"
    }
  )
}

# SecurityHub
resource "aws_network_acl_rule" "public-ingress_ingress_ssh_ipv6" {
  count          = var.lb_type != "none" ? 1 : 0
  network_acl_id  = aws_network_acl.public-ingress[0].id
  rule_number     = 6022
  egress          = false
  protocol        = "tcp"
  rule_action     = "deny"
  ipv6_cidr_block = "::/0"
  from_port       = 22
  to_port         = 22
}

resource "aws_network_acl_rule" "public-ingress_ingress_rdp_ipv6" {
  count          = var.lb_type != "none" ? 1 : 0
  network_acl_id  = aws_network_acl.public-ingress[0].id
  rule_number     = 6389
  egress          = false
  protocol        = "tcp"
  rule_action     = "deny"
  ipv6_cidr_block = "::/0"
  from_port       = 3389
  to_port         = 3389
}

# TODO move external to ELB
# HTTP External Requests
resource "aws_network_acl_rule" "public-ingress_ingress_http_ipv6" {
  count          = var.lb_type != "none" ? 1 : 0
  network_acl_id  = aws_network_acl.public-ingress[0].id
  rule_number     = 6080
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 80
  to_port         = 80
}

# HTTPS External Requests
resource "aws_network_acl_rule" "public-ingress_ingress_https_ipv6" {
  count          = var.lb_type != "none" ? 1 : 0
  network_acl_id  = aws_network_acl.public-ingress[0].id
  rule_number     = 6443
  egress          = false
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

# Ephemeral Ports for External Requests
resource "aws_network_acl_rule" "public-ingress_egress_ephemeral_ipv6" {
  count          = var.lb_type != "none" ? 1 : 0
  network_acl_id  = aws_network_acl.public-ingress[0].id
  rule_number     = 6999
  egress          = true
  protocol        = "tcp"
  rule_action     = "allow"
  ipv6_cidr_block = "::/0"
  from_port       = 1024
  to_port         = 65535
}
