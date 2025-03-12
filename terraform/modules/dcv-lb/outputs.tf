# outputs.tf

output "alb_id" {
  value = aws_lb.app.id
}

output "security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "http_listener_id" {
  value = aws_lb_listener.http.id
}

output "https_listener_id" {
  value = aws_lb_listener.https.id
}

output "dcv_server_listener_id" {
  value = aws_lb_listener.dcv-server.id
}

output "node_listener_id" {
  value = aws_lb_listener.node.id
}