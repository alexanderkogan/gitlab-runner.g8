data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  docker_machine_subnet_cidr = "10.190.229.0/27"
  gitlab_runner_subnet_cidr  = "10.190.229.32/28"
  // must correspond to the amount of IPs in docker_machine_subnet_cidr
  concurrent_jobs = 30

  gitlab_runner_version        = "13.8.0"
  docker_machine_version       = "0.16.2"
  docker_machine_instance_type = "m5.xlarge"

  ecr_nodejs_repository = ".dkr.ecr.eu-central-1.amazonaws.com/build-nodejs"
  bucket_prefix = "$bucketPrefix$"
}

resource "aws_eip" "gitlab_runner" {
  vpc  = true
}

resource "aws_nat_gateway" "gitlab_runner" {
  allocation_id = aws_eip.gitlab_runner.id
  subnet_id     = aws_subnet.gitlab_runner_subnet.id
}

resource "aws_subnet" "gitlab_runner_subnet" {
  vpc_id                  = local.vpc_id
  cidr_block              = local.gitlab_runner_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_route_table" "gitlab_runner" {
  vpc_id = local.vpc_id
}

resource "aws_route" "gitlab_runner_internet_gateway" {
  route_table_id         = aws_route_table.gitlab_runner.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.internet_gateway_id
}

resource "aws_route_table_association" "gitlab_runner" {
  subnet_id      = aws_subnet.gitlab_runner_subnet.id
  route_table_id = aws_route_table.gitlab_runner.id
}

resource "aws_security_group" "gitlab-runner" {
  name_prefix = "gitlab-runner"
  vpc_id      = local.vpc_id
  description = "A security group containing the gitlab-runner instance"

  ingress {
    description = "all ssh inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "all ping inbound"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "egress all gitlab runner"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "gitlab_docker_machine_subnet" {
  vpc_id            = local.vpc_id
  cidr_block        = local.docker_machine_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_route_table" "docker_machine" {
  vpc_id = local.vpc_id
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.docker_machine.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gitlab_runner.id
}

resource "aws_route_table_association" "docker_machine" {
  subnet_id      = aws_subnet.gitlab_docker_machine_subnet.id
  route_table_id = aws_route_table.docker_machine.id
}

resource "aws_security_group" "docker_machine" {
  name_prefix = "gitlab-runner-docker-machine"
  vpc_id      = local.vpc_id
  description = "A security group containing gitlab-runner docker-machine instances"

  ingress {
    description     = "gitlab runner to gitlab docker machine"
    from_port       = 2376
    to_port         = 2376
    protocol        = "tcp"
    security_groups = [aws_security_group.gitlab-runner.id]
  }

  ingress {
    description     = "gitlab runner to gitlab docker machine ssh"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.gitlab-runner.id]
  }

  ingress {
    description     = "gitlab runner to gitlab docker machine ping"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.gitlab-runner.id]
  }

  ingress {
    description = "gitlab docker machine to gitlab docker machine 2376"
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "gitlab docker machine to gitlab docker machine ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "gitlab docker machine to gitlab docker machine ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    self        = true
  }

  egress {
    description = "egress all gitlab docker machine"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "gitlab_runner" {
  most_recent = "true"
  name_regex  = "amzn2-ami-hvm-2.*-x86_64-ebs"
  owners      = ["amazon"]
}

resource "aws_key_pair" "gitlabrunner_public" {
  key_name   = "gitlabrunner-public-key"
  public_key = data.local_file.gitlabrunner-public-ssh-key.content
}

data "local_file" "gitlabrunner-private-ssh-key" {
  filename = "$"$"${path.module}/gitlabrunner/gitlab-runner-id_rsa"
}
data "local_file" "gitlabrunner-public-ssh-key" {
  filename = "$"$"${path.module}/gitlabrunner/gitlab-runner-id_rsa.pub"
}

locals {
  template_gitlab_runner_userdata = templatefile("./gitlabrunner/gitlab-runner-user-data.sh.tpl",
  {
    gitlab_runner_version            = local.gitlab_runner_version
    docker_machine_version           = local.docker_machine_version
    gitlab_docker_machine_user_data  = local.template_docker_machine_userdata
    gitlab_docker_machine_config     = local.template_gitlab_docker_machine_config
    gitlab_runner_registration_token = var.registration_token
    gitlab_runner_ssh_private_key    = data.local_file.gitlabrunner-private-ssh-key.content
    gitlab_runner_ssh_public_key     = data.local_file.gitlabrunner-public-ssh-key.content
    ecr_url                          = module.build_image.repository_url
  }
  )
  template_docker_machine_userdata = templatefile("./gitlabrunner/gitlab-runner-docker-machine-user-data.sh.tpl",
  {
    ecr_url = module.build_image.repository_url
  }
  )

  template_gitlab_docker_machine_config = templatefile("./gitlabrunner/gitlab-docker-machine-config.toml.tpl",
  {
    aws_region                                      = data.aws_region.current.id
    gitlab_docker_machine_name                      = "gl-dm"
    gitlab_runner_cache_bucket_name                 = module.gitlabrunner_build_cache.bucket.bucket
    gitlab_runner_ssh_public_key                    = aws_key_pair.gitlabrunner_public.key_name
    gitlab_docker_machine_concurrent                = local.concurrent_jobs
    gitlab_docker_machine_instance_type             = local.docker_machine_instance_type
    gitlab_docker_machine_aws_zone                  = trimprefix(data.aws_availability_zones.available.names[0], data.aws_region.current.id)
    gitlab_docker_machine_vpc_id                    = local.vpc_id
    gitlab_docker_machine_subnet_id                 = aws_subnet.gitlab_docker_machine_subnet.id
    gitlab_docker_machine_security_group_name       = aws_security_group.docker_machine.name
    gitlab_docker_machine_iam_instance_profile_name = aws_iam_instance_profile.docker_machine.name
    gitlab_docker_machine_root_size                 = "20"
    gitlab_docker_machine_tags                      = "Name,gitlab-docker-machine-instance"

    // This overwrites the default Docker Machine AMI which is Ubuntu 16.04, because it's deprecated by AWS.
    // That's a Ubuntu 20.04 AMI, but you can replace it with one of your choice, if you want.
    // Remove this once https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/issues/49 is fixed
    gitlab_docker_machine_ami = "ami-0d3905203a039e3b0"
  }
  )

}

resource "aws_instance" "gitlab_runner_instance" {
  vpc_security_group_ids = [aws_security_group.gitlab-runner.id]
  ami                    = data.aws_ami.gitlab_runner.image_id
  user_data              = local.template_gitlab_runner_userdata
  instance_type          = "m5.large"
  iam_instance_profile   = aws_iam_instance_profile.gitlab_runner.name
  subnet_id              = aws_subnet.gitlab_runner_subnet.id
  monitoring             = true
  root_block_device {
    delete_on_termination = true
    volume_size           = 20 #GB
    volume_type           = "gp2"
  }

  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ami]
  }
}

module "gitlabrunner_build_cache" {
  source          = "modules/aws_s3_bucket"
  name            = "$"$"${local.bucket_prefix}gitlabrunner-cache"
  owner_tag       = "Owner"
}
