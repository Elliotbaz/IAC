# Secrets Manager Secrets
resource "aws_secretsmanager_secret" "run_dcv_in_batch" {
  # name = "${local.prefix}-dcv-run-batch"
  name = "Run_DCV_in_Batch"
}

resource "aws_secretsmanager_secret_version" "run_dcv_in_batch" {
  secret_id     = aws_secretsmanager_secret.run_dcv_in_batch.id
  secret_string = jsonencode({
    "${var.dcv_username}" = var.dcv_password
  })
}

resource "aws_sns_topic" "dcv_session_ready_notification" {
  # name = "${local.prefix}-dcv-session-ready"
  name = "DCV_Session_Ready_Notification"
}

resource "aws_secretsmanager_secret" "dcv_session_ready_notification" {
  name = "DCV_Session_Ready_Notification"
}

resource "aws_secretsmanager_secret_version" "dcv_session_ready_notification" {
  secret_id     = aws_secretsmanager_secret.dcv_session_ready_notification.id
  secret_string = jsonencode({
    sns_topic_arn = aws_sns_topic.dcv_session_ready_notification.arn
  })
}

resource "aws_iam_role" "dcv_ecs_batch_role" {
  name = "dcv-ecs-batch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "dcv_ecs_batch_policy" {
  name        = "dcv-ecs-batch-policy"
  description = "Allows the ECS Batch job to download the DCV license file from S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:GetObject",
        Resource = "arn:aws:s3:::dcv-license.${var.region}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dcv_ecs_batch_policy" {
  role       = aws_iam_role.dcv_ecs_batch_role.name
  policy_arn = aws_iam_policy.dcv_ecs_batch_policy.arn
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryFullAccess" {
  role       = aws_iam_role.dcv_ecs_batch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "SecretsManagerReadWrite" {
  role       = aws_iam_role.dcv_ecs_batch_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "AmazonSNSFullAccess" {
  role       = aws_iam_role.dcv_ecs_batch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy" {
  role       = aws_iam_role.dcv_ecs_batch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}