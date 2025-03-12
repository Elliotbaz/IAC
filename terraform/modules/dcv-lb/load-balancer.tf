# lb.tf
resource "aws_lb" "app" {
  name               = "${var.prefix}-dcv-${var.suffix}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets
  enable_deletion_protection = false
  enable_http2                = true
  enable_cross_zone_load_balancing = true
  idle_timeout = 60
  tags = merge(var.tags, {
    Name = "${var.prefix}-dcv"
  })
}

# put a listener on port 80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Hello, World!"
      status_code  = "200"
    }
  }
}

# put a listener on port 443
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Hello, World!"
      status_code  = "200"
    }
  }
}

# DCV Server Listener
resource "aws_lb_listener" "dcv-server" {
  load_balancer_arn = aws_lb.app.arn
  port              = 8443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Hello, DCV Server!"
      status_code  = "200"
    }
  }
}

# DCV Server Listener
resource "aws_lb_listener" "node" {
  load_balancer_arn = aws_lb.app.arn
  port              = 3001
  protocol          = "HTTP"
  # ssl_policy        = "ELBSecurityPolicy-2016-08"
  # certificate_arn   = var.certificate_arn
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Hello, Node!"
      status_code  = "200"
    }
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.prefix}-dcv-alb-sg"
  vpc_id      = var.vpc_id
  description = "Allow all traffic to the ALB"
}

resource "aws_security_group_rule" "alb_sg_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_sg_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_sg_dcv" {
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "TCP"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_sg_node" {
  type              = "ingress"
  from_port         = 3001
  to_port           = 3001
  protocol          = "TCP"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# egress
resource "aws_security_group_rule" "alb_sg_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}