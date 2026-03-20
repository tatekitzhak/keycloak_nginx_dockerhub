# ------------------------------------------------------------------------------
# GitHub OIDC (OpenID Connect) for Actions – no long-lived IAM keys
# Terraform creates the Identity Provider and IAM Role; you assume the role
# in the workflow via aws-actions/configure-aws-credentials@v4 with the role ARN.
# ------------------------------------------------------------------------------


# GitHub's OIDC provider in this account (one per account)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "github-actions-oidc"
  }
}

# IAM Role that GitHub Actions can assume (trust policy only allows OIDC)
resource "aws_iam_role" "github_actions" {
  name        = "github-actions-oidc-role"
  description = "Role for GitHub Actions (OIDC); used by CD workflow for Terraform and SSM deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "github-actions-oidc-role"
  }
}

# Policy: allow SSM SendCommand to EC2 and describe instances (for CD deploy job)
resource "aws_iam_role_policy" "github_actions_ssm" {
  name = "github-actions-ssm-deploy"
  role = aws_iam_role.github_actions.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMSendCommand"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations"
        ]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

# Optional: attach a policy so this role can run Terraform (create VPC, EC2, IAM, etc.).
# Uncomment and run first apply with credentials that can create IAM; then set AWS_ROLE in GitHub.
# For production, replace with a custom policy that only allows required resources.
# resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
#   role       = aws_iam_role.github_actions.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

data "aws_region" "current" {}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions; set as secret AWS_ROLE in the repo"
  value       = aws_iam_role.github_actions.arn
}
