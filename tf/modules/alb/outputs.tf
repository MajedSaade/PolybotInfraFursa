############################
# modules/alb/outputs.tf
############################

output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "Public DNS name of the ALB"
}

output "alb_zone_id" {
  value       = aws_lb.this.zone_id
  description = "Hosted zone ID for the ALB (for Route53 alias)"
}

output "alb_sg_id" {
  value       = aws_security_group.this.id
  description = "Security Group ID for ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.this.arn
  description = "Target Group ARN attached to worker ASG"
}
