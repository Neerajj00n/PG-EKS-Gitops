output "cluster_name" {
  value = aws_eks_cluster.maincluster.name
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.eks.url
  
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
  
}

output "node_sg_id" {
  value = aws_security_group.node.id
}