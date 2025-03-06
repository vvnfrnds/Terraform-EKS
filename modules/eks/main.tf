resource "aws_iam_role" "cluster" {                 //Create IAM Role for EKS Cluster
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {  //Attach AmazonEKSClusterPolicy to IAM Role
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "main" {                         // Create EKS Cluster 
    name     = var.cluster_name
    version  = var.cluster_version
    role_arn = aws_iam_role.cluster.arn                     // Attach IAM Role to EKS Cluster
        
    vpc_config {
        subnet_ids = var.subnet_ids
    }

    depends_on = [ 
        aws_iam_role_policy_attachment.cluster_policy       // Wait for IAM Role to be created, then create EKS Cluster
     ]
}

resource "aws_iam_role" "node" {                        //Create IAM Role for EKS Node Group
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policy" {    //Attach AmazonEKSWorkerNodePolicy to IAM Role
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])
  policy_arn = each.value
  role      = aws_iam_role.node.name
}

resource "aws_eks_node_group" "main" {                     //Create EKS Node Group
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }
  depends_on = [ 
    aws_iam_role_policy_attachment.node_policy
   ]

}
