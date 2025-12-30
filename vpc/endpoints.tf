
data "aws_prefix_list" "endpoint" {
  count = length(["s3","dynamodb"])
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${local.region}.${element(["s3","dynamodb"], count.index)}"]
  }
}

resource "aws_security_group" "endpoint" {
  name   = "${local.name}-vpc-endpoint-security-group"
  vpc_id = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC private subnets"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = local.private_cidr
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
  for_each = toset(var.endpoints)

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${local.region}.${each.key}"
  vpc_endpoint_type = contains(["s3","dynamodb"], each.key) ? "Gateway" : "Interface"
  auto_accept       = true

  security_group_ids  = contains(["s3","dynamodb"], each.key) ? null : [aws_security_group.endpoint.id]  # Interface Only
  subnet_ids          = contains(["s3","dynamodb"], each.key) ? null : aws_subnet.private.*.id  # Interface Only
  route_table_ids     = contains(["s3","dynamodb"], each.key) ? concat(aws_route_table.private-gateway.*.id, aws_route_table.private-instance.*.id, aws_route_table.private.*.id) : null  # Gateway Only
  private_dns_enabled = contains(["s3","dynamodb"], each.key) ? false : true

  tags = merge(local.tags, { Name = "${each.key}-vpc-endpoint" })
}