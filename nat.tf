
# NAT IPs
resource "aws_eip" "nat" {
  count = var.nat_type != "none" ? local.az_count : 0
  vpc   = true

  tags = merge(
  local.tags,
  {
    Name = "${local.az_name[count.index]}-${local.name}"
  }
  )
}

# NAT Gateway
resource "aws_nat_gateway" "public-egress" {
  count         = var.nat_type == "gateway" ? local.az_count : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public-egress[count.index].id

  tags = merge(
  local.tags,
  {
    Name = "nat-${local.az_name[count.index]}-${local.name}"
  }
  )
}


# NAT Instance

data "aws_ami" "nat" {
  count       = var.nat_type == "instance" ? local.az_count : 0
  most_recent = true

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-nat", # amzn2-ami-hvm-*-arm64-nat
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm",
    ]
  }

  owners = [
    var.ami_account_id]
}

#tfsec:ignore:aws-autoscaling-no-public-ip
resource "aws_launch_configuration" "nat" {
  count                = var.nat_type == "instance" ? local.az_count : 0
  #spot_price          = "0.0001"
  name_prefix          = "${local.name}-nat-${local.az_name[count.index]}-"
  image_id             = data.aws_ami.nat[0].image_id
  key_name             = var.key_name
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.main[count.index].name
  security_groups      = [
    aws_security_group.nat[0].id
  ]
  user_data            = templatefile("${path.module}/user_data.sh", {
    BANNER                = "NAT ${local.az_name[count.index]}"
    EIP_ID                = aws_eip.nat[count.index].id
    SUBNET_ID             = aws_subnet.private[count.index].id
    ROUTE_TABLE_ID        = aws_route_table.private-egress-instance[count.index].id
    VPC_CIDR              = var.cidr_block
    IAM_AUTHORIZED_GROUPS = var.iam_user_groups
    SUDOERS_GROUPS        = var.iam_sudo_groups
    LOCAL_GROUPS          = ""
  })
  ebs_optimized        = "false"
  enable_monitoring    = "true"

  # Must be true in public subnets if assigning EIP in userdata
  associate_public_ip_address = "true"

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }

  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = true
    encrypted             = true
  }

  lifecycle {
    create_before_destroy = "true"
  }
}

#tfsec:ignore:aws-autoscaling-no-public-ip
resource "aws_autoscaling_group" "nat" {
  count                     = var.nat_type == "instance" ? local.az_count : 0
  name                      = "${local.name}-nat-${local.az_name[count.index]}-asg"
  max_size                  = "1"
  min_size                  = "1"
  desired_capacity          = "1"
  health_check_grace_period = 30
  launch_configuration      = aws_launch_configuration.nat[count.index].name

  vpc_zone_identifier = [
    aws_subnet.public-egress[count.index].id,
  ]

  dynamic "tag" {
    for_each = merge(local.tags, {
      Name = "${local.name}-nat-${local.az_name[count.index]}"
    })
    content {
      key   = tag.key
      value = tag.value

      propagate_at_launch = true
    }
  }
}

## SG
resource "aws_security_group" "nat" {
  count  = var.nat_type == "instance" ? 1 : 0
  name   = "${local.name}-nat-security-group"
  description = "NAT proxy access to internet"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80

    cidr_blocks = aws_subnet.private-egress.*.cidr_block
  }

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443

    cidr_blocks = aws_subnet.private-egress.*.cidr_block
  }

  egress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80

    cidr_blocks = [
      "0.0.0.0/0",
    ]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443

    cidr_blocks = [
      "0.0.0.0/0",
    ]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
  local.tags,
  {
    Name = "${local.name}-nat"
  }
  )
}

## IAM
resource "aws_iam_instance_profile" "main" {
  count = var.nat_type == "instance" ? local.az_count : 0
  name  = "${local.name}-nat-${local.az_name[count.index]}-instance-profile"
  role  = aws_iam_role.main[count.index].name
}

resource "aws_iam_role" "main" {
  count = var.nat_type == "instance" ? local.az_count : 0
  name  = "${local.name}-nat-${local.az_name[count.index]}-role"
  assume_role_policy = data.aws_iam_policy_document.role-main.json
}

data "aws_iam_policy_document" "role-main" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "main-nat" {
  count       = var.nat_type == "instance" ? local.az_count : 0
  name        = "${local.name}-nat-${local.az_name[count.index]}-route-policy"
  path        = "/"
  description = "${local.name} NAT EIP & Route Tables Policy"
  policy = data.aws_iam_policy_document.main-nat.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards Has condition in place
data "aws_iam_policy_document" "main-nat" {
  statement {
    sid = "ManageEC2"
    effect = "Allow"
    actions = ["ec2:AssociateAddress",
      "ec2:ReplaceRoute",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:DescribeRouteTables",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstanceAttribute",
      "ec2:ModifyInstanceAttribute"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = aws_subnet.public-egress.*.id
      variable = "ec2:Subnet"
    }
  }
}

resource "aws_iam_role_policy_attachment" "main-nat" {
  count      = var.nat_type == "instance" ? local.az_count : 0
  role       = aws_iam_role.main[count.index].name
  policy_arn = aws_iam_policy.main-nat[count.index].arn
}

resource "aws_iam_policy" "main-iam" {
  count       = var.nat_type == "instance" ? local.az_count : 0
  name        = "${local.name}-nat-${local.az_name[count.index]}-iam-policy"
  path        = "/"
  description = "${local.name} NAT SSH IAM Policy"
  policy = data.aws_iam_policy_document.main-iam.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards Their public keys ...
data "aws_iam_policy_document" "main-iam" {
  statement {
    sid = "ListUsers"
    effect = "Allow"
    actions = ["iam:ListUsers",
      "iam:GetGroup"]
    resources = ["*"]
  }
  statement {
    sid = "GetSSHKeys"
    effect = "Allow"
    actions = ["iam:GetSSHPublicKey",
      "iam:ListSSHPublicKeys"]
    resources = ["*"]
  }
  statement {
    sid = "ForgetWhatThisIsFor"
    effect = "Allow"
    actions = ["ec2:DescribeTags"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "main-iam" {
  count      = var.nat_type == "instance" ? local.az_count : 0
  role       = aws_iam_role.main[count.index].name
  policy_arn = aws_iam_policy.main-iam[count.index].arn
}

resource "aws_iam_role_policy_attachment" "main-cloudwatch-logs" {
  count      = var.nat_type == "instance" ? local.az_count : 0
  role       = aws_iam_role.main[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "main-cloudwatch-agent" {
  count      = var.nat_type == "instance" ? local.az_count : 0
  role       = aws_iam_role.main[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "main-ssm-agent" {
  count      = var.nat_type == "instance" ? local.az_count : 0
  role       = aws_iam_role.main[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

//resource "aws_iam_role_policy_attachment" "main-ssm-patch" {
//  count      = var.nat_type == "instance" ? local.az_count : 0
//  role       = aws_iam_role.main[count.index].name
//  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
//}

resource "aws_iam_role_policy_attachment" "main-xray" {
  count      = var.nat_type == "instance" ? local.az_count : 0
  role       = aws_iam_role.main[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# EC2 Output
output "nat_iam_role_name" {
  value = aws_iam_role.main.*.name
}

//output "nat_security_group_id" {
//  value = aws_security_group.nat[0].id
//}

output "billing_suggestion" {
  value = "Reserved Instances: ${var.instance_type} x ${local.az_count} (${local.region})"
}

