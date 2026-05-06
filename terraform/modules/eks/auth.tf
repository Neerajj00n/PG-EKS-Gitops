# EKS aws-auth ConfigMap
# This configures who can access the cluster via kubectl
provider "kubernetes" {
  host                   = aws_eks_cluster.maincluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.maincluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.mainclusterauth.token
}

# data "aws_eks_cluster_auth" "mainclusterauth" {
#   name = aws_eks_cluster.maincluster.name
# }



resource "aws_eks_access_entry" "user_access" {
  cluster_name  = aws_eks_cluster.maincluster.name
  principal_arn = var.cluster_creator_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "user_admin" {
  cluster_name  = aws_eks_cluster.maincluster.name
  principal_arn = aws_eks_access_entry.user_access.principal_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}