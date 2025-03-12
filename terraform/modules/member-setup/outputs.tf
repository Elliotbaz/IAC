output "member_account_role_arn" {
  value = aws_iam_role.github_actions_member.arn
  description = "The ARN of the role that Terraform will assume in the member account."
}