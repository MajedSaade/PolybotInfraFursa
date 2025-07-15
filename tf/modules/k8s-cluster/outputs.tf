output "control_plane_public_ip" {
  value = aws_instance.control_plane.public_ip
}

output "worker_asg_name" {
  value = aws_autoscaling_group.worker_asg.name
}

output "vpc_id" {
  value       = var.vpc_id
  description = "The ID of the VPC where the cluster is deployed"
}
output "hosted_zone_id" {
  value       = data.aws_route53_zone.primary.zone_id
  description = "The ID of the hosted zone"
}
output "polybot_dns" {
  description = "DNS name for Polybot Ingress"
  value       = aws_route53_record.polybot.fqdn
}
