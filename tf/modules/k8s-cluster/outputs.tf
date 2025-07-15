output "control_plane_public_ip" {
  value = aws_instance.control_plane.public_ip
}
output "worker_asg_name" {
  value = aws_autoscaling_group.worker_asg.name
}