# An s3 bucket for development resources
resource "aws_s3_bucket" "dev" {
  bucket_prefix = "${local.prefix}-artifacts-"
  tags = merge(local.common_tags, {
    Name = lower("${local.prefix}-artifacts")
  })
}

# Create a policy that allows managing objects in the bucket
resource "aws_iam_policy" "artifact_bucket" {
  name        = "${local.prefix}-artifact-bucket-policy"
  description = "Allows managing objects in the artifact bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource = [
          aws_s3_bucket.dev.arn,
          "${aws_s3_bucket.dev.arn}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the instance role
resource "aws_iam_role_policy_attachment" "artifact_bucket" {
  role       = aws_iam_role.poc.name
  policy_arn = aws_iam_policy.artifact_bucket.arn
}

output "artifact_bucket_name" {
  value = aws_s3_bucket.dev.bucket  
}