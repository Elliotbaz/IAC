# ssh key
resource "aws_key_pair" "poc" {
  key_name   = "${local.prefix}-poc"
  public_key = var.ssh_public_key
}

# data "aws_ami" "ecs_gpu_optimized_ami" {
#   most_recent = true
#   owners       = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-ecs-hvm-*-gpu*-x86_64-ebs"]
#   }
# }

# resource "aws_launch_template" "poc" {
#   name_prefix   = "${local.prefix}-poc"
#   image_id      = var.ami_id
#   instance_type = var.instance_type
#   key_name      = aws_key_pair.poc.key_name
#   user_data     = templatefile("${path.module}/userdata-${var.platform}.tpl", {
#     project        = var.project,
#     environment    = var.environment,
#     prefix         = local.prefix,
#     log_group_name = aws_cloudwatch_log_group.poc.name
#   })

#   block_device_mappings {
#     device_name = "/dev/xvda"
#     ebs {
#       volume_size = 20
#       volume_type = "gp3"
#       encrypted   = true
#     }
#   }

#   tag_specifications {
#     resource_type = "instance"
#     tags = merge(local.common_tags, {
#       Name = lower("${local.prefix}-poc")
#     })
#   }
# }

resource "aws_instance" "poc" {
  count = 1
  ami                    = var.ami_id
  # ami                    = data.aws_ami.ecs_gpu_optimized_ami.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.poc_instance.id]
  iam_instance_profile   = aws_iam_instance_profile.poc.name
  key_name               = aws_key_pair.poc.key_name
  user_data = templatefile("${path.module}/userdata-${var.platform}.tpl", {
    project        = var.project,
    environment    = var.environment,
    prefix         = local.prefix,
    log_group_name = aws_cloudwatch_log_group.poc.name
    s3_bucket      = aws_s3_bucket.dev.bucket
  })

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = var.volume_size
  }

  tags = merge(local.common_tags, {
    Name = lower("${local.prefix}-poc")
  })
}

resource "aws_cloudwatch_log_group" "poc" {
  name              = "${local.prefix}-poc"
  retention_in_days = 7
}

# output "instance_public_ip" {
#   value = aws_instance.poc.public_ip  
# }

output "instance_platform" {
  value = var.platform
}

resource "aws_iam_instance_profile" "poc" {
  name = lower("${var.project}-${var.environment}-poc-instance-profile")
  role = aws_iam_role.poc.name

  tags = merge(local.common_tags, {
    Name = lower("${var.project}-${var.environment}-poc-instance-profile")
  })
}

resource "aws_iam_role" "poc" {
  name = lower("${var.project}-${var.environment}-poc-role")
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

  tags = merge(local.common_tags, {
    Name = lower("${var.project}-${var.environment}-poc-role")
  })
}

resource "aws_iam_policy" "cloudwatch" {
  name        = lower("${var.project}-${var.environment}-poc-cloudwatch-policy")
  description = "Allows the POC instance to write logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "${aws_cloudwatch_log_group.poc.arn}:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.poc.name
  policy_arn = aws_iam_policy.cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "dcv_ecs_batch_policy_builder" {
  role       = aws_iam_role.poc.name
  policy_arn = aws_iam_policy.dcv_ecs_batch_policy.arn
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryFullAccess_builder" {
  role       = aws_iam_role.poc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "SecretsManagerReadWrite_builder" {
  role       = aws_iam_role.poc.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "AmazonSNSFullAccess_builder" {
  role       = aws_iam_role.poc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy_builder" {
  role       = aws_iam_role.poc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}