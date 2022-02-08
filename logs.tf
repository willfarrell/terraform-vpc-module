
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
  retention_in_days = var.retention_in_days
  kms_key_id = var.kms_key_arn
}

resource "aws_iam_role" "logs" {
  name = "${local.name}-vpc-logs-role"
  assume_role_policy = data.aws_iam_policy_document.role-logs.json
}

data "aws_iam_policy_document" "role-logs" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["vpc-flow-logs.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "logs" {
  name = "${local.name}-vpc-logs-policy"
  role = aws_iam_role.logs.id
  policy = data.aws_iam_policy_document.logs.json
}

data "aws_iam_policy_document" "logs" {
  statement {
    sid = "CloudWatchLogs"
    effect = "Allow"
    actions = ["logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"]
    resources = ["${aws_cloudwatch_log_group.logs.arn}"]
  }
}