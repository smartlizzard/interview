# Output the VPC IDs
output "vpc_ids" {
  value = aws_vpc.tenant[*].id
}

output "vpn_gateway_id_tenant0" {
  value = aws_vpn_gateway.tenant0_vpn.id
}

output "ec2_tenant1_id" {
  value = aws_instance.tenant_ec2.id
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.my_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.my_cluster.certificate_authority[0].data
}