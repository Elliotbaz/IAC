resource "aws_cloudwatch_log_group" "server" {
  name              = "${var.prefix}-dcv-server"
  retention_in_days = 7
}

resource "aws_launch_template" "dcv-server" {
  name_prefix   = "${var.prefix}-dcv-server"
  image_id      = var.ami_id #unofficial-amzn2-ami-ecs-gpu-hvm-2.0.20240725-x86_64-ebs (ECS Optimized with Nvidia 535.183.01 GPU drivers)
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

    iam_instance_profile {
        name = aws_iam_instance_profile.dcv_server_asg.name
    }

    network_interfaces {
        associate_public_ip_address = false
        delete_on_termination = true
        security_groups = [aws_security_group.dcv-server-asg.id]
    }

  user_data = base64encode(templatefile("${path.module}/user_data.tpl", { 
    prefix = var.prefix
    environment = var.environment
    cluster_name = aws_ecs_cluster.dcv.name
    object_bucket = var.object_bucket
    log_group_name = aws_cloudwatch_log_group.server.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.prefix}-dcv-server"
    }
  }
}

# DCV Server Autoscaling Group
resource "aws_autoscaling_group" "dcv-server" {
  name                      = "${var.prefix}-dcv-server"
  max_size                  = var.deploy_compute ? 1 : 0
  min_size                  = var.deploy_compute ? 1 : 0
  desired_capacity          = var.deploy_compute ? 1 : 0
  launch_template {
    id = aws_launch_template.dcv-server.id
    version = "$Latest"
  }
  vpc_zone_identifier       = var.private_subnets
  health_check_type         = "ELB"
  health_check_grace_period = 300
  termination_policies      = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "${var.prefix}-dcv-server"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "dcv-server" {
  name = "${var.prefix}-dcv-server"

  auto_scaling_group_provider {
    auto_scaling_group_arn          = aws_autoscaling_group.dcv-server.arn

    managed_scaling {
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "dcv-server" {
  cluster_name = aws_ecs_cluster.dcv.name

  capacity_providers = [aws_ecs_capacity_provider.dcv-server.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.dcv-server.name
    weight            = 100
  }
}