################################################################################
### gitlab runner instance profile
################################################################################
resource "aws_iam_instance_profile" "gitlab_runner" {
  name     = "gitlab-runner"
  role     = aws_iam_role.gitlab_runner.name
}
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "gitlab_runner" {
  name               = "gitlab-runner"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}
resource "aws_iam_role_policy_attachment" "gitlab_runner_tools" {
  role       = aws_iam_role.gitlab_runner.name
  policy_arn = aws_iam_policy.gitlab_runner_tools.arn
}
################################################################################
### docker machine instance profile
################################################################################
resource "aws_iam_instance_profile" "docker_machine" {
  name     = "gitlab-runner-docker-machine"
  role     = aws_iam_role.docker_machine.name
}
resource "aws_iam_role" "docker_machine" {
  name               = "gitlab-runner-docker-machine"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}
data "aws_iam_policy_document" "gitlab_runner_tools" {
  statement {
    actions = ["sts:GetServiceBearerToken"]
    resources = [
      "arn:aws:sts::$"$"${data.aws_caller_identity.current.account_id}:assumed-role/$"$"${aws_iam_role.gitlab_runner.name}/*",
      "arn:aws:sts::$"$"${data.aws_caller_identity.current.account_id}:assumed-role/$"$"${aws_iam_role.docker_machine.name}/*",
    ]
  }
  statement {
    actions = [
      "codeartifact:Describe*",
      "codeartifact:Get*",
      "codeartifact:List*",
      "codeartifact:Publish*",
      "codeartifact:Put*",
      "codeartifact:ReadFromRepository",
      "codeartifact:TagResource",
      "codeartifact:UntagResource",
      "codeartifact:UpdatePackageVersionsStatus",
      "codeartifact:UpdateRepository"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::gitlabrunner-cache/*"
    ]
  }
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeRegistry",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:PutImage",
      "ecr:StartImageScan",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:UploadLayerPart",
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = ["arn:aws:cloudfront::$"$"${data.aws_caller_identity.current.account_id}:distribution/*"]
  }
}
resource "aws_iam_policy" "gitlab_runner_tools" {
  name        = "gitlab-runner-tools"
  description = "Policy for gitlab-runner docker-machine instance"
  policy      = data.aws_iam_policy_document.gitlab_runner_tools.json
}
resource "aws_iam_role_policy_attachment" "gitlab_docker_machine" {
  role       = aws_iam_role.docker_machine.name
  policy_arn = aws_iam_policy.gitlab_runner_tools.arn
}
################################################################################
### Policies for gitlab runner to create docker machine instances via spot req.
################################################################################
data "aws_iam_policy_document" "gitlab_runner_create_spot" {
  statement {
    actions = [
      "ec2:Describe*",
      "ec2:RequestSpotInstances",
      "ec2:CancelSpotInstanceRequests",
      "ec2:CreateTags",
    ]
    resources = ["*"]
  }
  statement {
    actions   = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:$region$::image/ami-*"]
  }
  statement {
    actions = [
      "ec2:StartInstances",
      "ec2:RunInstances",
      "ec2:RebootInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances",
    ]
    resources = ["*"]
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.docker_machine.arn]
  }
  statement {
    actions   = ["ec2:AssociateIamInstanceProfile"]
    resources = [aws_iam_instance_profile.docker_machine.arn]
  }
}
resource "aws_iam_policy" "gitlab_runner_create_spot" {
  name     = "gitlab-runner-create-spot"
  policy   = data.aws_iam_policy_document.gitlab_runner_create_spot.json
}
resource "aws_iam_role_policy_attachment" "gitlab_runner_create_spot" {
  role       = aws_iam_role.gitlab_runner.name
  policy_arn = aws_iam_policy.gitlab_runner_create_spot.arn
}
################################################################################
### Policies for creating service linked roles for the gitlab runner
################################################################################
data "aws_iam_policy_document" "service_linked_role" {
  statement {
    actions = ["iam:CreateServiceLinkedRole"]
    resources = [
      "arn:aws:iam::$"$"${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.*",
      "arn:aws:iam::$"$"${data.aws_caller_identity.current.account_id}:role/aws-service-role/spot.*"
    ]
  }
}
resource "aws_iam_policy" "service_linked_role" {
  name        = "gitlab-runner-service-linked-role"
  description = "Policy for creation of service linked roles."
  policy      = data.aws_iam_policy_document.service_linked_role.json
}
resource "aws_iam_role_policy_attachment" "service_linked_role" {
  role       = aws_iam_role.gitlab_runner.name
  policy_arn = aws_iam_policy.service_linked_role.arn
}
