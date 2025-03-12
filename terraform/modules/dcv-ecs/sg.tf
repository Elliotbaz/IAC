# sg.tf

# DCV Server ASG Security Group
resource "aws_security_group" "dcv-server-asg" {
  name        = "${var.prefix}-dcv-server-asg"
  description = "Allow ingress from ALB"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "dcv-server-asg-alb-ingress" {
  type              = "ingress" # should probably be hardened to only 6443
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  security_group_id = aws_security_group.dcv-server-asg.id
  source_security_group_id = var.alb_sg_id
}

# Egress Rule
resource "aws_security_group_rule" "dcv-server-asg-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.dcv-server-asg.id
  cidr_blocks       = ["0.0.0.0/0"]
}