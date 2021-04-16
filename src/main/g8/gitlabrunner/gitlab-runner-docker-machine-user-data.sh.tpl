#!/bin/bash -e
apt update
apt install -y docker.io
systemctl enable --now docker

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt install -y unzip
unzip awscliv2.zip
sudo ./aws/install

tee /opt/aws_auth_cronjob.sh <<EOL
#!/bin/bash
set -euo pipefail
echo "AWS ECR Login"
aws ecr get-login-password --region $region$ | docker login -u AWS --password-stdin "$"$"${ecr_url}"
EOL
chmod +x /opt/aws_auth_cronjob.sh
/opt/aws_auth_cronjob.sh
echo "0 * * * * bash /opt/aws_auth_cronjob.sh" | crontab -
