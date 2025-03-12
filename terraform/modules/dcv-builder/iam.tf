resource "aws_iam_instance_profile" "builder" {
  name = "${var.prefix}-dcv-builder"
  path = "/"
  role = aws_iam_role.dcv_builder_asg.id
}

resource "aws_iam_role" "dcv_builder_asg" {
  name                = "${var.prefix}-dcv-builder"
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.dcv_builder_asg.json
}

data "aws_iam_policy_document" "dcv_builder_asg" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.dcv_builder_asg.name
  policy_arn = aws_iam_policy.cloudwatch.arn
}

resource "aws_iam_policy" "cloudwatch" {
  name        = lower("${var.prefix}-dcv-builder-cloudwatch")
  description = "Allows the DCV Builder instance to write logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "${aws_cloudwatch_log_group.builder.arn}:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.dcv_builder_asg.name
  policy_arn = aws_iam_policy.ecs.arn
}

resource "aws_iam_policy" "ecs" {
  name        = lower("${var.prefix}-dcv-builder-ecs")
  description = "Allows the DCV Builder instance to interact with ECS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:RegisterContainerInstance",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Submit*",
        "ecs:Poll",
        "ecs:StartTelemetrySession",
        "ecs:UpdateContainerInstancesState",
        "ecs:SubmitContainerStateChange",
        "ecs:SubmitTaskStateChange"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryFullAccess_builder" {
  role       = aws_iam_role.dcv_builder_asg.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# {
#     "log": "level=error time=2024-08-12T16:35:04Z msg=\"Error registering container instance\" error=\"AccessDeniedException: User: arn:aws:sts::585415957264:assumed-role/intraverse-dev-dcv-builder/i-07a83249602c21466 is not authorized to perform: ecs:RegisterContainerInstance on resource: arn:aws:ecs:us-east-1:585415957264:cluster/default because no identity-based policy allows the ecs:RegisterContainerInstance action\"\n",
#     "stream": "stdout",
#     "time": "2024-08-12T16:35:04.394715736Z"
# }

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerServiceforEC2Role_builder" {
  role       = aws_iam_role.dcv_builder_asg.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "s3-scripts-bucket" {
  role       = aws_iam_role.dcv_builder_asg.name
  policy_arn = aws_iam_policy.s3-scripts-bucket.arn
}

# ability to pull objects from the s3 object bucket
resource "aws_iam_policy" "s3-scripts-bucket" {
  name        = lower("${var.prefix}-dcv-builder-s3-scripts-bucket")
  description = "Allows the DCV Builder instance to pull scripts from the S3 bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}