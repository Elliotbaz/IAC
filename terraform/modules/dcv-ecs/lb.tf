# lb.tf

resource "aws_lb_target_group" "dcv-server" {
  name        = "${var.prefix}-dcv-tg"
  port        = 8443
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener_rule" "dcv-server" {
  listener_arn = var.dcv_server_listener_id
  priority = 101
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dcv-server.arn
  }
  condition {
    host_header {
      values = ["*.${var.domain}*"]
    }
  }
}

# lb.tf

resource "aws_lb_target_group" "nginx-ec2" {
  name        = "${var.prefix}-nginx-ec2"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

# listen on port 443
resource "aws_lb_listener_rule" "nginx" {
  listener_arn = var.https_listener_id
  # forward to the target group
    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.nginx-ec2.arn
    }
  condition {
    host_header {
      values = ["*.${var.domain}*"]
    }
  }
}