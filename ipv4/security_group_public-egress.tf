
resource "aws_security_group" "public-egress" {
  count          = var.nat_type == "zonal" ? 1 : 0
  name   = "${local.name}-public-egress-security-group"
  vpc_id = aws_vpc.main.id

  tags = merge(
	local.tags,
	{
	  Name = "${local.name}-public-egress"
	}
  )
}

resource "aws_vpc_security_group_egress_rule" "public-egress_https_ipv4" {
	count          = var.nat_type == "zonal" ? 1 : 0
	description = "Allow outbound access"
  	security_group_id = aws_security_group.public-egress[0].id
	from_port         = 443
	to_port           = 443
    ip_protocol       = "tcp"
    cidr_ipv4         = "0.0.0.0/0"
}
