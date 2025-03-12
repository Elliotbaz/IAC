# policy to allow capacity provider to pull images from ECR
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "intraverse-utils-ecr-policy" 
  role = "intraverse-dev-ecs-instance-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ecs:RegisterContainerInstance",
            "ecs:DeregisterContainerInstance",
            "ecs:DiscoverPollEndpoint",
            "ecs:Submit*",
            "ecs:Poll",
            "ecs:StartTelemetrySession",
            "ecs:UpdateContainerInstancesState",
            "ecs:SubmitContainerStateChange",
            "ecs:SubmitTaskStateChange",
            "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}