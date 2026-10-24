
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Project   = "devops-portfolio"
    ManagedBy = "Terraform"
  }
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Akshata-07/sample-application:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_ecr" {
  name               = "github-actions-sample-application-ecr"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json

  tags = {
    Project   = "devops-portfolio"
    ManagedBy = "Terraform"
  }
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = [
      aws_ecr_repository.application.arn
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name   = "push-sample-application-to-ecr"
  role   = aws_iam_role.github_actions_ecr.id
  policy = data.aws_iam_policy_document.ecr_push.json
}

output "github_actions_role_arn" {
  description = "IAM role assumed by GitHub Actions through OIDC"
  value       = aws_iam_role.github_actions_ecr.arn
}
