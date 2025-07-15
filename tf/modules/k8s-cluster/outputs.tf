output "control_plane_public_ip" {
  value = aws_instance.control_plane.public_ip
}

output "worker_asg_name" {
  value = aws_autoscaling_group.worker_asg.name
}

output "polybot_dns" {
  value       = aws_route53_record.polybot.fqdn
  description = "Public DNS name for the polybot service"
}

output "vpc_id" {
  value       = var.vpc_id
  description = "The ID of the VPC where the cluster is deployed"
}
