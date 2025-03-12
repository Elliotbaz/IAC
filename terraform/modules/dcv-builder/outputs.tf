output "launch_template_id" {
  value = aws_launch_template.dcv-builder.id
}

output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.builder.name
}