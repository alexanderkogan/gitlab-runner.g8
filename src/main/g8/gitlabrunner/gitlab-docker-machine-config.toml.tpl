concurrent = ${gitlab_docker_machine_concurrent}
check_interval = 0

[[runners]]
name = "${gitlab_docker_machine_name}"
url = "https://gitlab.com"
# must correspond to placeholder in gitlab-runner.sh.tpl
token = "__REPLACED_BY_USER_DATA__"
executor = "docker+machine"
builds_dir = "/home/app/repository"
[runners.docker]
image = "docker:19"
pull_policy = "if-not-present"
tls_verify = false
privileged = false
disable_cache = false
volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/certs/client", "/cache", "/home/app/repository:/home/app/repository:rw"]
[runners.cache]
Type = "s3"
Shared = true
[runners.cache.s3]
ServerAddress = "s3.amazonaws.com"
BucketName = "${gitlab_runner_cache_bucket_name}"
BucketLocation = "${aws_region}"
[runners.machine]
IdleCount = 0
IdleTime = 3600
MachineDriver = "amazonec2"
MachineName = "${gitlab_docker_machine_name}-%s"
MachineOptions = [
  # file is created in gitlab-runner-user-data.sh.tpl.
  # expects public key with same name and pub suffix next to it.
  "amazonec2-ssh-keypath=/etc/gitlab-runner/id_rsa",
  "amazonec2-keypair-name=${gitlab_runner_ssh_public_key}",
  "amazonec2-instance-type=${gitlab_docker_machine_instance_type}",
  # file is created in gitlab-runner-user-data.sh.tpl.
  "amazonec2-userdata=/etc/gitlab-runner/machine-user-data.sh",
  "amazonec2-region=${aws_region}",
  "amazonec2-zone=${gitlab_docker_machine_aws_zone}",
  "amazonec2-vpc-id=${gitlab_docker_machine_vpc_id}",
  "amazonec2-subnet-id=${gitlab_docker_machine_subnet_id}",
  "amazonec2-use-private-address=true",
  "amazonec2-request-spot-instance=true",
  "amazonec2-security-group=${gitlab_docker_machine_security_group_name}",
  "amazonec2-iam-instance-profile=${gitlab_docker_machine_iam_instance_profile_name}",
  "amazonec2-root-size=${gitlab_docker_machine_root_size}",
  "amazonec2-tags=${gitlab_docker_machine_tags}",
  "amazonec2-ami=${gitlab_docker_machine_ami}"
]

[[runners.machine.autoscaling]]
Periods = ["* * 8-19 * * mon-fri *"]
IdleCount = 1
IdleTime = 3600
Timezone = "Europe/Berlin"
