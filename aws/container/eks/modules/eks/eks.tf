resource "aws_security_group" "cluster" {
  name        = "${var.local_name_prefix}eks-cluster-${var.name}"
  description = "Security group for the eks cluster"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "node" {
  name        = "${var.local_name_prefix}eks-node-${var.name}"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                                                  = "${var.local_name_prefix}eks-node-${var.name}"
    "kubernetes.io/cluster/${aws_eks_cluster.cluster.name}" = "owned"
  }
}

resource "aws_security_group_rule" "node-ingress-self" {
  description              = "Allow nodes to communicate with each other"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id

  type      = "ingress"
  protocol  = "-1"
  from_port = 0
  to_port   = 65535
}

resource "aws_security_group_rule" "node-ingress-cluster" {
  description              = "Allow nodes to receive communication from the cluster"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 1025
  to_port   = 65535
}

resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443
}

resource "aws_iam_role" "cluster" {
  name = "${var.local_name_prefix}eks-${var.name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "service-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = var.node_role
}

resource "aws_iam_role_policy_attachment" "node-cni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = var.node_role
}

resource "aws_iam_role_policy_attachment" "node-container-registry-readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = var.node_roles
}

resource "aws_eks_cluster" "cluster" {
  name     = "${var.local_name_prefix}${var.name}"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    security_group_ids = [
      aws_security_group.cluster.id,
      compact(var.cluster_ssecurity_groups),
    ]
    subnet_ids = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-policy,
    aws_iam_role_policy_attachment.service-policy,
  ]
}

data "aws_iam_role" "node_role" {
  name = var.node_role
}

data "aws_ami" "worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

