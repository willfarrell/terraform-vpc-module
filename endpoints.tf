# https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/vpc-endpoints.tf

######################
# VPC Endpoint for S3
######################
data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
}

resource "aws_vpc_endpoint" "s3" {
  count        = contains(var.endpoints, "s3") ? 1 : 0
  vpc_id       = aws_vpc.main.id
  service_name = data.aws_vpc_endpoint_service.s3.service_name
  tags = merge(
  local.tags,
  {
    Name = "${local.name}-s3"
  }
  )

  /*policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
      {
        "Sid": "Access to ECR",
        "Principal": "*",
        "Action": [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:s3:::prod-${local.workspace["region"]}-starport-layer-bucket/*"
        ]
      },
      {
          "Sid":"S3 Buckets",
          "Effect": "Allow",
          "Action": [
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ],
          "Resource": [
            "arn:aws:s3:::*"
          ],
          "Principal": "*",
          "Condition": {
            "StringEquals": {
              "aws:SourceVpce": "${module.vpc.id}"
            }
          }
      },
      {
          "Sid":"S3 Objects",
          "Effect": "Allow",
          "Action": [
            "s3:*"
          ],
          "Resource": [*/
            //"arn:aws:s3:::*/*"
         /* ],
          "Principal": "*",
          "Condition": {
            "StringEquals": {
              "aws:SourceVpce": "${module.vpc.id}"
            }
          }
      },
      {
        "Sid":"ADMINRequiredForECS",
        "Effect":"Allow",
        "Action":["*"],
        "Resource":["*"],
        "Principal": "*"
      }
  ]
}
POLICY*/
}

resource "aws_vpc_endpoint_route_table_association" "private_none_s3" {
  count           = contains(var.endpoints, "s3") && var.nat_type == "none" ? local.az_count : 0
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = element(aws_route_table.private.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "private_instance_s3" {
  count           = contains(var.endpoints, "s3") && var.nat_type == "instance" ? local.az_count : 0
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = element(aws_route_table.private-instance.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "private_gateway_s3" {
  count           = contains(var.endpoints, "s3") && var.nat_type == "gateway" ? local.az_count : 0
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = element(aws_route_table.private-gateway.*.id, count.index)
}

/*resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  count           = contains(var.endpoints, "s3") ? 1 : 0
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.public.id
}*/

############################
# VPC Endpoint for DynamoDB
############################
data "aws_vpc_endpoint_service" "dynamodb" {
  service = "dynamodb"
}

resource "aws_vpc_endpoint" "dynamodb" {
  count        = contains(var.endpoints, "dynamodb") ? 1 : 0
  vpc_id       = aws_vpc.main.id
  service_name = data.aws_vpc_endpoint_service.dynamodb.service_name
  tags = merge(
  local.tags,
  {
    Name = "${local.name}-dynamodb"
  }
  )
}

resource "aws_vpc_endpoint_route_table_association" "private_none_dynamodb" {
  count           = contains(var.endpoints, "dynamodb") && var.nat_type == "none" ? local.az_count : 0
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = element(aws_route_table.private.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "private_instance_dynamodb" {
  count           = contains(var.endpoints, "dynamodb") && var.nat_type == "instance" ? local.az_count : 0
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = element(aws_route_table.private-instance.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "private_gateway_dynamodb" {
  count           = contains(var.endpoints, "dynamodb") && var.nat_type == "gateway" ? local.az_count : 0
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = element(aws_route_table.private-gateway.*.id, count.index)
}

/*resource "aws_vpc_endpoint_route_table_association" "public_dynamodb" {
  count           = contains(var.endpoints, "dynamodb") ? 1 : 0
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.public.id
}*/

// ...

#######################
# VPC Endpoint for SQS
#######################
/*data "aws_vpc_endpoint_service" "sqs" {
  service = "sqs"
}

resource "aws_vpc_endpoint" "sqs" {
  count        = contains(var.endpoints, "sqs") ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = data.aws_vpc_endpoint_service.sqs.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = var.sqs_endpoint_security_group_ids
  subnet_ids          = aws_subnet.private.*.id
  private_dns_enabled = true
  tags                = {}
}*/