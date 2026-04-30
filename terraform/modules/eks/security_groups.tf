resource "aws_security_group" "cluster" {
  name_prefix = "${var.project_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, { Name = "${var.project_name}-cluster-sg" })
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "node" {
  name_prefix = "${var.project_name}-node-sg-"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name                                        = "${var.project_name}-node-sg"
      "kubernetes.io/cluster/${var.project_name}" = "owned"
    }
  )
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "node_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
  description              = "Allow nodes to communicate with cluster API"
}


resource "aws_security_group_rule" "cluster_to_node" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  description              = "Allow cluster control plane to communicate with nodes"
}

resource "aws_security_group_rule" "node_ingress_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  description              = "API server webhooks"
}
resource "aws_security_group_rule" "node_to_node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  self              = true
  description       = "Allow nodes to communicate with each other"
}
