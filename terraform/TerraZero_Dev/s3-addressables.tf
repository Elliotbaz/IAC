# Create an S3 Bucket for Addressables for Aux
resource "aws_s3_bucket" "addressables_aux" {
  bucket = "addressables-aux-${local.suffix}"
  tags   = local.common_tags
}

# Enable versioning to keep multiple versions of objects
resource "aws_s3_bucket_versioning" "addressables_aux_versioning" {
  bucket = aws_s3_bucket.addressables_aux.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

# Apply a bucket policy to allow public read access to all objects
resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.addressables_aux.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPublicReadAccess"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.addressables_aux.arn}/*"
      }
    ]
  })
}