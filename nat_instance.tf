# local.az_count == length(var.public_subnet_ids)

resource "aws_route_table" "private-instance" {
  count  = var.nat_type == "instance" ? local.az_count : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name = "private-nat-${local.name}-${local.az_name[count.index]}"
    }
  )
}

resource "aws_route_table_association" "private-instance" {
  count          = var.nat_type == "instance" ? local.az_count : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private-instance[count.index].id
}

# instance
# *************************************
# module { count } is not supported :(

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
    var.ami_account_id
  ]
}

resource "aws_launch_template" "nat" {
  count = var.nat_type == "instance" ? local.az_count : 0

  name                   = "${local.name}-nat-${local.az_name[count.index]}"
  image_id               = data.aws_ami.nat[0].image_id
  key_name               = var.key_name
  instance_type          = var.instance_type
  ebs_optimized          = false
  update_default_version = true

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    BANNER                = "NAT ${local.az_name[count.index]}"
    EIP_ID                = aws_eip.nat[count.index].id
    SUBNET_ID             = aws_subnet.private[count.index].id
    ROUTE_TABLE_ID        = aws_route_table.private-instance[count.index].id
    VPC_CIDR              = var.cidr_block
    IAM_AUTHORIZED_GROUPS = var.iam_user_groups
    SUDOERS_GROUPS        = var.iam_sudo_groups
    LOCAL_GROUPS          = ""
  }))

  block_device_mappings {
    device_name = data.aws_ami.nat[count.index].root_device_name

    ebs {
      volume_type           = var.volume_type
      volume_size           = var.volume_size
      delete_on_termination = true
      encrypted             = true
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.main[count.index].arn
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    # Must be true in public subnets if assigning EIP in userdata
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [aws_security_group.nat[0].id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }
}

resource "aws_autoscaling_group" "nat" {
  count                     = var.nat_type == "instance" ? local.az_count : 0
  name                      = "${local.name}-nat-${local.az_name[count.index]}-asg"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 30

  launch_template {
    id      = aws_launch_template.nat[count.index].id
    version = "$Latest"
  }

  vpc_zone_identifier = [
    aws_subnet.public[count.index].id,
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
  vpc_id = aws_vpc.main.id

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80

    cidr_blocks = aws_subnet.private.*.cidr_block
  }

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443

    cidr_blocks = aws_subnet.private.*.cidr_block
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

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "main-nat" {
  count       = var.nat_type == "instance" ? local.az_count : 0
  name        = "${local.name}-nat-${local.az_name[count.index]}-route-policy"
  path        = "/"
  description = "${local.name} NAT EIP & Route Tables Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Action": [
          "ec2:AssociateAddress",
          "ec2:ReplaceRoute",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:DescribeRouteTables",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstanceAttribute",
          "ec2:ModifyInstanceAttribute"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
}
EOF

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

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:ListUsers",
        "iam:GetGroup"
      ],
      "Resource": "*"
    }, {
      "Effect": "Allow",
      "Action": [
        "iam:GetSSHPublicKey",
        "iam:ListSSHPublicKeys"
      ],
      "Resource": [
        "arn:aws:iam::${local.account_id}:user/*"
      ]
    }, {
        "Effect": "Allow",
        "Action": "ec2:DescribeTags",
        "Resource": "*"
    }
  ]
}
EOF

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

