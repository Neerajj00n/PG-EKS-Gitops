data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/image_id"
}


resource "aws_launch_template" "app_nodes" {
  name_prefix   = "${var.project_name}-app"
  image_id      = data.aws_ssm_parameter.eks_ami.value

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           =  var.disk_size_app
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.node.id]
    delete_on_termination       = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    /etc/eks/bootstrap.sh ${aws_eks_cluster.maincluster.name} \
      --b64-cluster-ca ${aws_eks_cluster.maincluster.certificate_authority[0].data} \
      --apiserver-endpoint ${aws_eks_cluster.maincluster.endpoint}
  EOF
  )
  

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-app-node" }
  }

  lifecycle { create_before_destroy = true }
}


# -----------------------------------------------
# Node Group 1 — On-Demand base (always running)
# -----------------------------------------------
resource "aws_eks_node_group" "app_ondemand" {
  cluster_name    = aws_eks_cluster.maincluster.name
  node_group_name = "app-ondemand"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = "ON_DEMAND"    # <-- On-Demand
  
  instance_types = [var.app_ondemand_nodes.instance_type]   # single type is fine for On-Demand

  launch_template {
    id      = aws_launch_template.app_nodes.id
    version = aws_launch_template.app_nodes.latest_version
  }

  scaling_config {
    min_size     = var.app_ondemand_nodes.min
    max_size     = var.app_ondemand_nodes.max
    desired_size = var.app_ondemand_nodes.desired
  }

  update_config { max_unavailable = 1 }

  labels = {
    role         = "app"
    capacity     = "on-demand"
  }

  depends_on = [
    var.node_worker_policy,
    var.node_cni_policy,
    var.node_ecr_policy
  ]
}


# -----------------------------------------------
# Node Group 2 — Spot scaling (adds on demand)
# -----------------------------------------------
resource "aws_eks_node_group" "app_spot" {
  cluster_name    = aws_eks_cluster.maincluster.name
  node_group_name = "app-spot"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = "SPOT"         # <-- Spot

  instance_types = var.app_spot_nodes.instance_types

  launch_template {
    id      = aws_launch_template.app_nodes.id
    version = aws_launch_template.app_nodes.latest_version
  }

  scaling_config {
    min_size     = var.app_ondemand_nodes.min  # can scale to zero when no extra load
    max_size     = var.app_ondemand_nodes.max   # Cluster Autoscaler will scale up to this
    desired_size = var.app_ondemand_nodes.desired  # start with same number of Spot nodes as On-Demand
  }

  update_config { max_unavailable = 1 }

  labels = {
    role     = "app"
    capacity = "spot"
  }

  taint {
    key    = "spot"
    value  = "true"
    effect = "PREFER_NO_SCHEDULE"   # prefer not, but allow if needed
  }


}


# -----------------------------------------------
# Observability node group — On-Demand only
# -----------------------------------------------
resource "aws_launch_template" "obs_nodes" {
  name_prefix   = "${var.project_name}-obs"
  image_id      = data.aws_ssm_parameter.eks_ami.value

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size_obs
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.node.id]
    delete_on_termination       = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    /etc/eks/bootstrap.sh ${aws_eks_cluster.maincluster.name} \
      --b64-cluster-ca ${aws_eks_cluster.maincluster.certificate_authority[0].data} \
      --apiserver-endpoint ${aws_eks_cluster.maincluster.endpoint}
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-obs-node" }
  }
}

resource "aws_eks_node_group" "observability" {
  cluster_name    = aws_eks_cluster.maincluster.name
  node_group_name = "observability-nodes"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = "ON_DEMAND"   # always On-Demand for monitoring
  instance_types = [var.obs_nodes.instance_type]

  launch_template {
    id      = aws_launch_template.obs_nodes.id
    version = aws_launch_template.obs_nodes.latest_version
  }

  scaling_config {
    min_size     = var.obs_nodes.min
    max_size     = var.obs_nodes.max
    desired_size = var.obs_nodes.desired
  }

  update_config { max_unavailable = 1 }

  labels = { role = "observability" }

  taint {
    key    = var.obs_nodes.taint_key
    value  = var.obs_nodes.taint_value
    effect = var.obs_nodes.taint_effect
  }


}