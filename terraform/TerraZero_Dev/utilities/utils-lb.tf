resource "aws_lb" "dcv-server-lb" {
  name               = "${local.prefix}-dcv-server-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = local.public_subnets
  security_groups    = [aws_security_group.dcv-server-sg.id]
}

resource "aws_lb_target_group" "dcv-server-tg" {
  name     = "${local.prefix}-dcv-server-tg"
  port     = 8443
  protocol = "HTTPS"
  vpc_id   = local.vpc_id
  target_type = "instance"

  health_check {
    port                = 8443
    protocol            = "HTTPS"
    interval            = 30
    # timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "dcv-server-listener" {
  load_balancer_arn = aws_lb.dcv-server-lb.arn
  port              = 8443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:585415957264:certificate/f00cc958-e460-4498-8f4a-5d508a4e8221"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dcv-server-tg.arn
  }
}

resource "aws_lb_target_group_attachment" "dcv-server-attachment" {
  target_group_arn = aws_lb_target_group.dcv-server-tg.arn
#   target_id        = aws_instance.builder.id
    target_id = "i-08f7d66623d6c82ac"
  port             = 8443
}

resource "aws_lb_target_group" "dcv-server-ecs-tg" {
  name     = "${local.prefix}-dcv-ecs-tg"
  port     = 8443
  protocol = "HTTPS"
  vpc_id   = local.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }
}

# resource "aws_lb_listener" "dcv-server-ecs-listener" {
#   load_balancer_arn = aws_lb.dcv-server-lb.arn
#   port              = 8443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = "arn:aws:acm:us-east-1:585415957264:certificate/f00cc958-e460-4498-8f4a-5d508a4e8221"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.dcv-server-ecs-tg.arn
#   }
# }

resource "aws_lb_target_group_attachment" "dcv-server-eni-attachment" {
  target_group_arn = aws_lb_target_group.dcv-server-ecs-tg.arn
  target_id        = "10.1.3.46"
  port             = 8443
}


#######################################
# Security Groups
#######################################
resource "aws_security_group" "dcv-server-sg" {
  name   = "${local.prefix}-dcv-server-sg"
  vpc_id = local.vpc_id
  tags   = local.common_tags
}

resource "aws_security_group_rule" "dcv-server-alb-ingress-http" {
  type                    = "ingress"
  from_port              = 80
  to_port                = 80
  protocol               = "tcp"
  security_group_id      = aws_security_group.dcv-server-sg.id
  cidr_blocks            = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "dcv-server-alb-ingress-https" {
  type                    = "ingress"
  from_port              = 443
  to_port                = 443
  protocol               = "tcp"
  security_group_id      = aws_security_group.dcv-server-sg.id
  cidr_blocks            = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "dcv-server-alb-ingress-custom" {
  type                    = "ingress"
  from_port              = 8443
  to_port                = 8443
  protocol               = "tcp"
  security_group_id      = aws_security_group.dcv-server-sg.id
  cidr_blocks            = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "dcv-server-alb-egress" {
  type                    = "egress"
  from_port              = 0
  to_port                = 0
  protocol               = "-1"
  security_group_id      = aws_security_group.dcv-server-sg.id
  cidr_blocks            = ["0.0.0.0/0"]
}

