
resource "aws_security_group" "private-egress" {
  name   = "${local.name}-private-egress-security-group"
  vpc_id = aws_vpc.main.id

  tags = merge(
	local.tags,
	{
	  Name = "${local.name}-private-egress"
	}
  )
}

# HTTP
resource "aws_vpc_security_group_egress_rule" "private-egress_http_ipv6" {
  description = "Allow outbound access"

  security_group_id = aws_security_group.private-egress.id
	from_port         = 80
	to_port           = 80
	ip_protocol       = "tcp"
	cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_egress_rule" "private-egress_http_ipv64" {
  description = "Allow outbound access"

  security_group_id = aws_security_group.private-egress.id
	from_port         = 80
	to_port           = 80
	ip_protocol       = "tcp"
  cidr_ipv6         = "64:ff9b::/96"
}

# HTTPS
resource "aws_vpc_security_group_egress_rule" "private-egress_https_ipv6" {
  description = "Allow outbound access"

  security_group_id = aws_security_group.private-egress.id
	from_port         = 443
	to_port           = 443
	ip_protocol       = "tcp"
    cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_egress_rule" "private-egress_https_ipv64" {
  description = "Allow outbound access"

  security_group_id = aws_security_group.private-egress.id
	from_port         = 443
	to_port           = 443
	ip_protocol       = "tcp"
  cidr_ipv6         = "64:ff9b::/96"
}