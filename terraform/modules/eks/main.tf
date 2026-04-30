# ── KMS Key ───────────────────────────────────────────────────────────────────
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster ${var.project_name} encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(        # Fix 1: was merge({ Name = "..." }) — missing var.tags
    var.tags,
    {
      Name = "${var.project_name}-eks-kms"
    }
  )
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.project_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}/cluster"
  retention_in_days = 7
  #kms_key_id        = aws_kms_key.eks.arn   # Fix 2: encrypt logs with your KMS key
}

# ── Security Groups ───────────────────────────────────────────────────────────



# ── EKS Cluster ───────────────────────────────────────────────────────────────
resource "aws_eks_cluster" "maincluster" {
  name     = "${var.project_name}-eks-cluster"
  role_arn = var.eks_role_arn
  version  = var.cluster_version

  access_config {
    authentication_mode = "CONFIG_MAP"
  }

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]  # Fix 3: was missing
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = var.public_access_cidrs
  }

  # Fix 4: KMS envelope encryption was missing
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [    
    var.eks_role_arn,    # Ensure the EKS cluster role exists before creating the cluster
    aws_cloudwatch_log_group.eks
  ]
}

# ── Addons ────────────────────────────────────────────────────────────────────
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.maincluster.name
  addon_name                  = "kube-proxy"
  addon_version               = var.kube_proxy_version != "" ? var.kube_proxy_version : null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = var.tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.maincluster.name
  addon_name                  = "coredns"
  addon_version               = var.coredns_version != "" ? var.coredns_version : null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.app_ondemand]
}
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.maincluster.name
  addon_name                  = "vpc-cni"
  addon_version               = var.vpc_cni_version != "" ? var.vpc_cni_version : null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.maincluster.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
}   

#-------IRSA / IAM OIDC Provider for EKS -------

data "tls_certificate" "eks" {
  url = aws_eks_cluster.maincluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.maincluster.identity[0].oidc[0].issuer
  tags            = { Name = "${var.project_name}-oidc" }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.project_name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}

data "aws_iam_policy_document" "ebs_csi_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.eks.url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

# In your existing EKS terraform
resource "aws_eks_access_entry" "terraform_user" {
  cluster_name  = aws_eks_cluster.maincluster.name
  principal_arn = "arn:aws:iam::327414657131:user/terraform-user"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "terraform_user_admin" {
  cluster_name  = aws_eks_cluster.maincluster.name
  principal_arn = "arn:aws:iam::327414657131:user/terraform-user"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
