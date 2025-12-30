resource "aws_security_group" "private" {
  name   = "${local.name}-private-security-group"
  vpc_id = aws_vpc.main.id

  tags = merge(
	local.tags,
	{
	  Name = "${local.name}-private"
	}
  )
}

# IMDSv2
resource "aws_vpc_security_group_egress_rule" "privats_imds_ipv4" {
  description = "Allow outbound access"

  security_group_id = aws_security_group.private.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "169.254.169.254/32"
}