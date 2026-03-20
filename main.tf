# AWS provider configuration for LocalStack
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    iam            = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

# Permissions Boundary Policy: The "Hard Limit"
# This policy defines the maximum permissions that can ever be granted to a delegated user/role.
resource "aws_iam_policy" "boundary" {
  name        = "StandardUserPermissionsBoundary"
  description = "Defines the absolute maximum permissions for delegated roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowCommonServices"
        Effect   = "Allow"
        Action   = [
          "s3:*",
          "ec2:*",
          "lambda:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      },
      {
        Sid      = "DenyHighRiskActions"
        Effect   = "Deny"
        Action   = [
          "iam:Delete*",
          "organizations:*",
          "account:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Delegated Admin IAM Role: The "Junior Admin"
# This role can create other roles, but ONLY if it attaches the boundary defined above.
resource "aws_iam_role" "delegated_admin" {
  name = "junior-cloud-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Delegated Admin Policy: Enforces the use of the boundary
resource "aws_iam_role_policy" "delegated_admin_policy" {
  name = "junior-admin-capability-policy"
  role = aws_iam_role.delegated_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy"
        ]
        Resource = "*"
        # Condition: Role creation is ONLY allowed if the boundary is attached
        Condition = {
          StringEquals = {
            "iam:PermissionsBoundary" = aws_iam_policy.boundary.arn
          }
        }
      },
      {
        Sid    = "AllowRoleViewing"
        Effect = "Allow"
        Action = [
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Outputs: Key identifiers for governance verification
output "boundary_policy_arn" {
  value = aws_iam_policy.boundary.arn
}

output "delegated_admin_role_name" {
  value = aws_iam_role.delegated_admin.name
}
