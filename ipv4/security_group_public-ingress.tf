
resource "aws_security_group" "public-ingress" {
  count          = var.lb_type != "none" ? 1 : 0
  name   = "${local.name}-public-ingress-security-group"
  vpc_id = aws_vpc.main.id

  tags = merge(
	local.tags,
	{
	  Name = "${local.name}-public-ingress"
	}
  )
}

resource "aws_vpc_security_group_ingress_rule" "public-ingress_https_ipv4" {
  count          = var.lb_type != "none" ? 1 : 0
  description = "Allow inbound access"

  security_group_id = aws_security_group.public-ingress[0].id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
