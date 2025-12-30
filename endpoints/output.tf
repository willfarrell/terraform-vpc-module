output "security_group" {
  description = "The security group ID"
  value = {
	vpc-endpoints        = aws_security_group.main.id
	vpc-endpoints-access = aws_security_group.access.id
  }
}