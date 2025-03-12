# TerraZero_QA Setup
These are the resources that need escalated privileges in order to bootstrap the initial Terraform setup for the member account that will ultimately have least privilege permissions. Due to the limited nature of these sensitive resources, it should be a small enough amount of code to plan out express here in a single markdown file. 

## Summary
We're going to create a role in the memeber account for Terraform to assume. This will be the role that we attach policies to that give the Terraform agent permissions to manage resources in the member account. This role will have an assume role policy that attempts to set up a trust relationship with the management account. This is for the purposes of being able to manage the state bucket, which we are putting in the central management account for consistency, manageability, and auditability. 

## Related Resources

### Member Account Terraform Agent Role
When an agent is using Terraform to manage resources in the member account, they will assume this role. 

Here's the Terraform code to create a role on a member account that is trusted by the management account to manage its state bucket:

#### Member Account (where the role is created):

```hcl
resource "aws_iam_role" "state_management_role" {
  name = "terraform-state-management-role"

  # Trust relationship allows the management account to assume this role
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<management_account_id>:root"  # Replace with actual management account ID
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# This policy allows the role to access the state bucket in the management account
resource "aws_iam_policy" "state_management_policy" {
  name = "terraform-state-management-access"

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
        "arn:aws:s3:::<management_account_id>-terraform-state",  # Replace with actual bucket name
        "arn:aws:s3:::<management_account_id>-terraform-state/*"  # Allow access to all objects within the bucket
      ]
    }
  ]
}
EOF

  attach_inline_policy = true
}

# Optional: Output the role ARN for reference in the management account
output "role_arn" {
  value = aws_iam_role.state_management_role.arn
}

```

Once this role is created, we will need the output of its arn in order to complete the setup of the trust relationship from the management account. Once this trust relationship is properly set up, we can continue to attach policies to the role in the member account for the management of specific resources on the member account.

### Management Account Terraform Sandbox Backend Role


## Unity 