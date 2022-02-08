
data "aws_prefix_list" "endpoint" {
  count = length(["s3","dynamodb"])
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${local.region}.${element(["s3","dynamodb"], count.index)}"]
  }
}

resource "aws_security_group" "endpoint" {
  name   = "${local.name}-vpc-endpoint-security-group"
  description = "Access to VPC Endpoints"
  vpc_id = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC private subnets"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = concat(local.private-egress-cidr, local.private-cidr)
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  egress {
    description = "Connect to AWS Services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = data.aws_prefix_list.endpoint.*.id
  }

  tags = merge(local.tags,
  {
    Name = "${local.name}-vpc-endpoint"
  })
}

resource "aws_vpc_endpoint" "main" {
  for_each = var.endpoints

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${local.region}.${each.key}"
  vpc_endpoint_type = contains(["s3","dynamodb"], each.key) ? "Gateway" : "Interface"
  auto_accept       = true

  security_group_ids  = contains(["s3","dynamodb"], each.key) ? null : [aws_security_group.endpoint.id]  # Interface Only
  subnet_ids          = contains(["s3","dynamodb"], each.key) ? null : concat(aws_subnet.private-egress.*.id, aws_subnet.private.*.id)  # Interface Only
  route_table_ids     = contains(["s3","dynamodb"], each.key) ? concat(aws_route_table.private-egress-gateway.*.id, aws_route_table.private-egress-instance.*.id, aws_route_table.private-egress-none.*.id, aws_route_table.private.*.id) : null  # Gateway Only
  private_dns_enabled = contains(["s3","dynamodb"], each.key) ? false : true  # Interface Only

  tags = merge(local.tags, { Name = "${each.key}-vpc-endpoint" })
}

# ACL
resource "aws_network_acl" "endpoints" {
  vpc_id = aws_vpc.main.id

  subnet_ids = concat(aws_route_table.private-egress-gateway.*.id, aws_route_table.private-egress-instance.*.id, aws_route_table.private-egress-none.*.id, aws_route_table.private.*.id)

  tags = merge(
  local.tags,
  {
    Name = "endpoints-${local.name}"
  }
  )
}

# HTTPS Internal Requests
resource "aws_network_acl_rule" "endpoints_egress-https-vpc-endpoint" {
  count          = length(aws_vpc_endpoint.main)
  network_acl_id = aws_network_acl.endpoints.id
  rule_number    = 4443
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = try(aws_vpc_endpoint.main[count.index].cidr_blocks, "0.0.0.0/0")
  from_port      = 443
  to_port        = 443
}

# Ephemeral Ports for Internal Requests

#tfsec:ignore:aws-vpc-no-public-ingress-acl
resource "aws_network_acl_rule" "endpoints_ingress-ephemeral-vpc-endpoint" {
  network_acl_id = aws_network_acl.endpoints.id
  rule_number    = 4999
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

#tfsec:ignore:aws-vpc-no-public-ingress-acl
resource "aws_network_acl_rule" "endpoints_ingress-ephemeral-vpc-endpoint" {
  network_acl_id = aws_network_acl.endpoints.id
  rule_number    = 4999
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "::/0"
  from_port      = 1024
  to_port        = 65535
}