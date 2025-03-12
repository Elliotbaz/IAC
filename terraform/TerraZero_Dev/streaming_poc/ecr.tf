# ECR Registry
resource "aws_ecr_repository" "poc" {
  name = "${local.prefix}-poc"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

# Create a policy that allows the instance to push images to the ECR repository
resource "aws_iam_policy" "poc_ecr" {
  name        = "${local.prefix}-poc-ecr-policy"
  description = "Allows the POC instance to push images to the ECR repository"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ],
        Resource = ["${aws_ecr_repository.poc.arn}/*", "${aws_ecr_repository.poc.arn}"]
      },
        {
            Effect   = "Allow",
            Action   = [
            "ecr:GetAuthorizationToken",
            ],
            Resource = "*"
        }
    ]
  })
}

# Attach the policy to the instance role
resource "aws_iam_role_policy_attachment" "poc_ecr" {
  role       = aws_iam_role.poc.name
  policy_arn = aws_iam_policy.poc_ecr.arn
}