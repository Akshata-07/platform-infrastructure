
# EKS identity provider used by the AWS Load Balancer Controller
resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  tags = {
    Project   = "devops-portfolio"
    ManagedBy = "Terraform"
  }
}

# Allow only the Load Balancer Controller service account to assume this role
data "aws_iam_policy_document" "load_balancer_controller_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "load_balancer_controller" {
  name               = "devops-portfolio-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.load_balancer_controller_assume_role.json

  tags = {
    Project   = "devops-portfolio"
    ManagedBy = "Terraform"
  }
}

# Load the official AWS Load Balancer Controller permissions policy
resource "aws_iam_policy" "load_balancer_controller" {
  name        = "devops-portfolio-load-balancer-controller"
  description = "Permissions for the AWS Load Balancer Controller"
  policy      = file("${path.module}/lbc-iam-policy.json")

  tags = {
    Project   = "devops-portfolio"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  role       = aws_iam_role.load_balancer_controller.name
  policy_arn = aws_iam_policy.load_balancer_controller.arn
}



