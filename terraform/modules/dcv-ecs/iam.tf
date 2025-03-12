# iam.tf

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.prefix}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role Policy
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "${var.prefix}-ecs-task-role-policy"
  role = aws_iam_role.ecs_task_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecs:UpdateService",
          "ecs:RunTask",
          "ecs:ListTaskDefinitions",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DetachNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecs:CreateCluster",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:Submit*",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "iam:PassRole"
        ],
        "Resource": aws_iam_role.ecs_task_execution_role.arn
      }
    ]
  })
}

# DCV Server ASG Instance Role
resource "aws_iam_role" "dcv_server_asg" {
  name                = "${var.prefix}-ecs-instance-role"
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.dcv_server_asg.json
}

data "aws_iam_policy_document" "dcv_server_asg" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "dcv_server_asg" {
  role        = aws_iam_role.dcv_server_asg.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "dcv_server_asg" {
  name = "${var.prefix}-ecs-instance-profile"
  path = "/"
  role = aws_iam_role.dcv_server_asg.id

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

data "aws_iam_policy_document" "ecs_instance_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:ListContainerInstances",
      "ecs:DescribeContainerInstances",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ecs:DescribeServices",
      "ecs:DescribeClusters"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_instance_permissions" {
  name        = "${var.prefix}-ecs-instance-permissions"
  path        = "/"
  description = "Allows ECS instances to describe and list ECS resources"
  policy      = data.aws_iam_policy_document.ecs_instance_permissions.json
}

resource "aws_iam_role_policy_attachment" "ecs_instance_permissions" {
  role       = aws_iam_role.dcv_server_asg.name
  policy_arn = aws_iam_policy.ecs_instance_permissions.arn
}

resource "aws_iam_role_policy_attachment" "s3-build-bucket" {
  role       = aws_iam_role.dcv_server_asg.name
  policy_arn = aws_iam_policy.s3-build-bucket.arn
}

# ability to pull objects from the s3 object bucket
resource "aws_iam_policy" "s3-build-bucket" {
  name        = lower("${var.prefix}-dcv-server-s3-scripts-bucket")
  description = "Allows the DCV Server instances to pull scripts from the S3 bucket"

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