# Unity Engineering IAM Role
The Unity Engineering team needs to be able to read objects from 4 different s3 buckets accross 4 different accounts. There will likely be other permissions required for this team in the future so let's make the role center around the team, not the current need.

## Terraform Management Accross Accounts
First, we need the ability to manage resources accross accounts with a central state bucket in the management account.

Here's an example Terraform configuration demonstrating storing state for multiple accounts in a single S3 bucket within the management account:

### 1. IAM Role and Policy (Management Account):

This role will be assumed by Terraform runs in member accounts to access the S3 bucket in the management account.

### Resource 1a: IAM Role

```hcl
resource "aws_iam_role" "s3_access_role" {
  name = "terraform-s3-access-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sts.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
```

### Resource 1b: IAM Policy

```hcl
resource "aws_iam_policy" "s3_access_policy" {
  name = "terraform-s3-access-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::<your-bucket-name>",
        "arn:aws:s3:::<your-bucket-name>/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.s3_access_role.id
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

```

### 2. S3 Bucket (Management Account):

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "<your-bucket-name>"
  acl    = "private"

  versioning {
    enabled = true
  }
}

```

### 3. Terraform Backend Configuration (Member Accounts):

This configuration assumes the role created in the management account and specifies the S3 bucket for state storage.

> Important: Replace <role-arn> with the actual role ARN from the management account.

```hcl
terraform {
  backend "s3" {
    bucket = aws_s3_bucket.terraform_state.bucket
    key    = "terraform.tfstate"
    region = "us-east-1" # Replace with your desired region

    # Assume the role with S3 access permissions
    role_arn = "<role-arn>"
  }
}
```

### Explanation:

- The IAM role and policy in the management account grant temporary access to the S3 bucket for Terraform runs in member accounts.
- The S3 bucket enables versioning for state history.
- The Terraform backend configuration in member accounts references the S3 bucket and assumes the IAM role with access permissions.

#### Note:

- This is a simplified example and doesn't include resource management for member accounts. You'll need separate configurations for managing infrastructure in each account.
- Remember to replace placeholders like <your-bucket-name> and <role-arn> with your actual values.
- Consider using workspaces within Terraform Cloud/Enterprise for further isolation and organization of state for different environments.