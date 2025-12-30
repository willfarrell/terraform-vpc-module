


data "aws_prefix_list" "endpoint" {
  count = length(local.gateways)
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${local.region}.${element(local.gateways, count.index)}"]
  }
}

resource "aws_security_group" "access" {
  name   = "${local.name}-vpc-endpoint-access-security-group"
  vpc_id = var.vpc_id
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-vpc-endpoint-access"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "access" {
  description   = "VPC private subnets to VPC endpoint via TLS"

  security_group_id = aws_security_group.access.id
  from_port        = 443
  to_port          = 443
  ip_protocol      = "tcp"
  referenced_security_group_id = aws_security_group.main.id
}

resource "aws_security_group" "main" {
  name   = "${local.name}-vpc-endpoint-security-group"
  vpc_id = var.vpc_id

  tags = merge(
    local.tags,
  {
    Name = "${local.name}-vpc-endpoint"
  })
}

resource "aws_vpc_security_group_egress_rule" "allow-access" {
  for_each = toset(var.allowed_security_groups)
  description   = "VPC private subnets to VPC endpoint via TLS"

  security_group_id = each.value
  from_port        = 443
  to_port          = 443
  ip_protocol      = "tcp"
  referenced_security_group_id = aws_security_group.main.id
}

resource "aws_vpc_security_group_ingress_rule" "endpoint-ingress" {
  for_each = toset(var.allowed_security_groups)
  description   = "VPC endpoint via TLS from VPC private subnets"

  security_group_id = aws_security_group.main.id
  from_port        = 443
  to_port          = 443
  ip_protocol      = "tcp"
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_egress_rule" "endpoint-egress" {
  for_each = toset(data.aws_prefix_list.endpoint.*.id)
  description   = "VPC endpoint via TLS to AWS Service"

  security_group_id = aws_security_group.main.id
  from_port   = 443
  to_port     = 443
  ip_protocol    = "tcp"
  prefix_list_id = each.value
}

resource "aws_vpc_endpoint" "main" {
  for_each = toset(var.endpoints)

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${local.region}.${each.key}"
  vpc_endpoint_type = contains(["s3","dynamodb"], each.key) ? "Gateway" : "Interface"
  auto_accept       = true
  
  # contains(local.gateways, each.key) ? Gateway Only : Interface Only
  security_group_ids  = contains(local.gateways, each.key) ? null : [aws_security_group.main.id]
  subnet_ids          = contains(local.gateways, each.key) ? null : var.allowed_subnet_ids
  route_table_ids     = contains(local.gateways, each.key) ? var.allowed_route_tables : null
  private_dns_enabled = contains(local.gateways, each.key) ? false : var.private_dns_enabled

  tags = merge(local.tags, { Name = "${each.key}-vpc-endpoint" })
}