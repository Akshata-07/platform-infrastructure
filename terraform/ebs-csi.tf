
# --------------------------------------------------
# IAM role for Amazon EBS CSI Driver
# --------------------------------------------------

resource "aws_iam_role" "ebs_csi" {
  name = "devops-portfolio-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "pods.eks.amazonaws.com"
      }

      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })

  tags = {
    Project   = "devops-portfolio"
    ManagedBy = "Terraform"
  }
}

# Grant permissions to create, attach and manage EBS volumes
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# --------------------------------------------------
# EKS Pod Identity Agent
# --------------------------------------------------

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"

  tags = {
    Project   = "devops-portfolio"
    ManagedBy = "Terraform"
  }
}

# --------------------------------------------------
# Amazon EBS CSI Driver Add-on
# --------------------------------------------------

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"

  pod_identity_association {
    role_arn        = aws_iam_role.ebs_csi.arn
    service_account = "ebs-csi-controller-sa"
  }

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.ebs_csi
  ]

  tags = {
    Project   = "devops-portfolio"
    ManagedBy = "Terraform"
  }
}
