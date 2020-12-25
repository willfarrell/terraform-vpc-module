
# Logs
resource "aws_flow_log" "logs" {
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.logs.arn
  iam_role_arn         = aws_iam_role.logs.arn
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/aws/vpc/${aws_vpc.main.id}"
  retention_in_days = 365
}

resource "aws_iam_role" "logs" {
  name = "${local.name}-vpc-logs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "logs" {
  name = "${local.name}-vpc-logs-policy"
  role = aws_iam_role.logs.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

}