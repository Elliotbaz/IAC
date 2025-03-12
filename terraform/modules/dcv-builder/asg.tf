resource "aws_cloudwatch_log_group" "builder" {
  name              = "${var.prefix}-dcv-builder"
  retention_in_days = 7
}

resource "aws_s3_object" "dcv-container-build-script" {
  bucket = var.object_bucket
  key    = "${var.prefix}-dcv-builder-scripts/dcv-container-build.sh"
  source = "${path.module}/scripts/dcv-container-build.sh"
  etag = filemd5("${path.module}/scripts/dcv-container-build.sh")
}

resource "aws_s3_object" "dcv-init-session" {
  bucket = var.object_bucket
  key    = "${var.prefix}-dcv-builder-scripts/init_session.sh"
  source = "${path.module}/scripts/init_session.sh"
  etag = filemd5("${path.module}/scripts/init_session.sh")
}

resource "aws_s3_object" "dcv-run-script" {
  bucket = var.object_bucket
  key    = "${var.prefix}-dcv-builder-scripts/run_script.sh"
  source = "${path.module}/scripts/run_script.sh"
  etag = filemd5("${path.module}/scripts/run_script.sh")
}

resource "aws_s3_object" "dcv-config" {
  bucket = var.object_bucket
  key    = "${var.prefix}-dcv-builder-scripts/dcvserver.service"
  source = "${path.module}/scripts/dcvserver.service"
  etag = filemd5("${path.module}/scripts/dcvserver.service")
}

resource "aws_s3_object" "dcv-dockerfile" {
  bucket = var.object_bucket
  key    = "${var.prefix}-dcv-builder-scripts/Dockerfile"
  source = "${path.module}/scripts/Dockerfile"
  etag = filemd5("${path.module}/scripts/Dockerfile")
}

resource "aws_s3_object" "dcv-send-notification" {
  bucket = var.object_bucket
  key    = "${var.prefix}-dcv-builder-scripts/send_dcvsessionready_notification.sh"
  source = "${path.module}/scripts/send_dcvsessionready_notification.sh"
  etag = filemd5("${path.module}/scripts/send_dcvsessionready_notification.sh")
}

resource "aws_s3_object" "dcv-startup-script" {
  bucket = var.object_bucket
  key    = "${var.prefix}-dcv-builder-scripts/startup_script.sh"
  source = "${path.module}/scripts/startup_script.sh"
  etag = filemd5("${path.module}/scripts/startup_script.sh")
}

resource "aws_launch_template" "dcv-builder" {
  name_prefix   = "${var.prefix}-dcv-builder"
  image_id      = var.ami_id #unofficial-amzn2-ami-ecs-gpu-hvm-2.0.20240725-x86_64-ebs (ECS Optimized with Nvidia 535.183.01 GPU drivers)
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

    iam_instance_profile {
        name = aws_iam_instance_profile.builder.name
    }

    # These will need to be protected behind a VPN and load balancer and not exposed to the public internet
    network_interfaces {
        associate_public_ip_address = true
        delete_on_termination = true
        security_groups = [aws_security_group.dcv-builder-asg.id]
    }

  # user_data = data.template_cloudinit_config.config.rendered
  user_data = base64encode(templatefile("${path.module}/user_data.tpl", { 
    prefix = var.prefix,
    log_group_name = aws_cloudwatch_log_group.builder.name,
    object_bucket = var.object_bucket,
    build_scripts_folder = "${var.prefix}-dcv-builder-scripts"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.prefix}-dcv-builder"
    }
  }
}

# DCV Server Autoscaling Group
resource "aws_autoscaling_group" "dcv-builder" {
  name                      = "${var.prefix}-dcv-builder"
  max_size                  = var.deploy_builder ? 1 : 0
  min_size                  = var.deploy_builder ? 1 : 0
  desired_capacity          = var.deploy_builder ? 1 : 0
  launch_template {
    id = aws_launch_template.dcv-builder.id
    version = "$Latest"
  }
  vpc_zone_identifier       = var.public_subnets
  health_check_type         = "ELB"
  health_check_grace_period = 300
  termination_policies      = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "${var.prefix}-dcv-builder"
    propagate_at_launch = true
  }
}