#!/bin/bash -e
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
tee /etc/hosts <<EOL
127.0.0.1   localhost localhost.localdomain $"$"$(hostname)
EOL

for i in {1..7}; do
  echo "Attempt: ---- " $"$"$i
  yum -y update && break || sleep 60
done

# ssh for developers
mkdir -p /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh
tee /home/ec2-user/.ssh/authorized_keys <<EOL
$developersSshKey$
EOL
chmod 600 /home/ec2-user/.ssh/authorized_keys

# gitlab runner setup
mkdir -p /etc/gitlab-runner
cat > /etc/gitlab-runner/config.toml <<- EOF
$"$"${gitlab_docker_machine_config}
EOF
cat > /etc/gitlab-runner/machine-user-data.sh <<- EOF
$"$"${gitlab_docker_machine_user_data}
EOF
cat > /etc/gitlab-runner/id_rsa <<- EOF
$"$"${gitlab_runner_ssh_private_key}
EOF
chmod 0600 /etc/gitlab-runner/id_rsa
cat > /etc/gitlab-runner/id_rsa.pub <<- EOF
$"$"${gitlab_runner_ssh_public_key}
EOF
chmod 0600 /etc/gitlab-runner/id_rsa.pub

amazon-linux-extras install docker
usermod -a -G docker ec2-user
systemctl enable docker
systemctl start docker

curl --fail --retry 6 -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash
yum install gitlab-runner-$"$"${gitlab_runner_version} -y

curl --fail --retry 6 -L https://github.com/docker/machine/releases/download/v$"$"${docker_machine_version}/docker-machine-$"$"$(uname -s)-$"$"$(uname -m) >/tmp/docker-machine

chmod +x /tmp/docker-machine && \
mv /tmp/docker-machine /usr/local/bin/docker-machine && \
ln -s /usr/local/bin/docker-machine /usr/bin/docker-machine
docker-machine --version
export USER=root
export HOME=/root
docker-machine create --driver none --url localhost dummy-machine
docker-machine rm -y dummy-machine
unset HOME
unset USER

yum install jq -y

auth_token=$"$"$(curl --request POST -L "https://gitlab.com/api/v4/runners" \
--form "token=$"$"${gitlab_runner_registration_token}" \
--form "description=gitlab-runner" \
--form "active=true" \
--form "locked=false" \
--form "run_untagged=true" \
| jq -r .token)

sed -i.bak s/__REPLACED_BY_USER_DATA__/`echo $"$"$auth_token`/g /etc/gitlab-runner/config.toml

service gitlab-runner restart
chkconfig gitlab-runner on

# cronjob for login
tee /opt/aws_auth_cronjob.sh <<EOL
#!/bin/bash
set -euo pipefail
echo "AWS ECR Login"
aws ecr get-login-password --region $region$ | docker login -u AWS --password-stdin "$"$"${ecr_url}"
EOL
chmod +x /opt/aws_auth_cronjob.sh
/opt/aws_auth_cronjob.sh
echo "0 * * * * bash /opt/aws_auth_cronjob.sh" | crontab -
