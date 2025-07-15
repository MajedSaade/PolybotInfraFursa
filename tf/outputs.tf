output "control_plane_public_ip" {
  value = module.k8s_cluster.control_plane_public_ip
}
output "vpc_id" {
  value = module.k8s_cluster.vpc_id
  description = "The ID of the VPC used by the Kubernetes cluster"
}
