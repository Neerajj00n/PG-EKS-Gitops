 output "cluster_role_arn" {
   value = aws_iam_role.cluster-role.arn
  
 }

output "node_group_role_arn" {
   value = aws_iam_role.node_group.arn
}

output "node_cni_policy" { 
    value = aws_iam_role_policy_attachment.node_cni_policy

}

output "node_worker_policy" {
    value = aws_iam_role_policy_attachment.node_worker_policy
  
}
output "node_ecr_policy" {
    value = aws_iam_role_policy_attachment.node_ecr_policy
  
}
# output "ebs_csi_role_arn" {
#   value = aws_iam_role.ebs_csi.arn
  
# }

output "backend_irsa_role_arn" {
  value = aws_iam_role.backend_irsa.arn
}