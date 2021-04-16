variable "repository_name" {
  description = "the name of this docker repository (aka image)"
  type        = string
}

variable "repository_accounts" {
  description = "list of accounts that can access this repository"
  type        = list(string)
}

variable "tags" {
  description = "tags to add to the ressources"
  type        = map(string)
}


resource "aws_ecr_repository" "ecr_repository" {
  name = var.repository_name
  tags = merge(var.tags, {
    Name = var.repository_name
  })
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "ecr_repository_policy" {
  repository = var.repository_name
  policy     = data.aws_iam_policy_document.ecr_repository_policy_document.json
}

data "aws_iam_policy_document" "ecr_repository_policy_document" {
  statement {
    sid    = aws_ecr_repository.ecr_repository.arn
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.repository_accounts
    }
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchDeleteImage",
      "ecr:CompleteLayerUpload",
      "ecr:DeleteRepositoryPolicy",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeRegistry",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:UntagResource",
      "ecr:UploadLayerPart",
      "ecr:PutImage",
      "ecr:SetRepositoryPolicy",
      "ecr:StartImageScan",
      "ecr:TagResource",
    ]
  }
}

output "repository_url" {
  value = aws_ecr_repository.ecr_repository.repository_url
}