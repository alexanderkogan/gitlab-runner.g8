A [Giter8][g8] template for ...!

# Template license
Written in 2021 by Alexander Kogan alexander.kogan@spaceteams.de

To the extent possible under law, the author(s) have dedicated all copyright and related
and neighboring rights to this template to the public domain worldwide.
This template is distributed without any warranty. See <http://creativecommons.org/publicdomain/zero/1.0/>.

[g8]: http://www.foundweekends.org/giter8/

# Description
This template creates an EC2 instance - the GitLab Runner - that will create Docker Machine instances to run jobs from GitLab pipelines.

# Properties
| Name                        | Description |
|-----------------------------|-------------|
|**addBoilerplate & region**  | If addBoilerplate is true, a main.tf will be created with the region.|
|**registrationToken**        | Needed to register the GitLab runner to a repository. You can get it in a GitLab repository from *Settings -> CI/CD -> Runners -> Set up a specific runner manually*. It is added by a .tfvars file, so that you can encrypt it for pushing it to a repository with git-crypt for example.|
|**vpcId & internetGatewayId**| VPC and internet gateway, that the runner should use. To enter Terraform outputs, you can use for example `$"$"${data.vpc_id}` to set the local as `"${data.vpc_id}"` or you can replace them afterwards.|
|**developersSshKey**         | SSH public key to allow developers to connect to the GitLab runner. If you want more than one, you have to add it in `gitlabrunner/gitlab-runner-user-data.sh.tpl` line 16.|
|**bucketPrefix**             | Since AWS S3 buckets have to have a globally unique name, it is advised to use a bucket prefix for your buckets. It is assumed, that the prefix ends on `-`.|  

# Setup after download
To make the template work you have to do some things after you download this.

## Create an SSH key for runner communication
The GitLab Runner needs an SSH key to connect to the Docker Machines. You need to create it and place the private and public key into the gitlabrunner folder.
If you want to push the keys to a repository, don't forget to encrypt them, for example with git-crypt.
The files have to be named:
* private key: `gitlab-runner-id_rsa`
* public key: `gitlab-runner-id_rsa.pub`

## Provide nodejs build image in ECR repository
You have to push an image to the build-image repository created by this code, that can be started by the Docker Machines to build your code.

## Adjust autoscaling of docker machines
The autoscaling in `gitlabrunner/gitlab-docker-machine-config.toml.tpl` line 51 assumes the timezone as "Europe/Berlin" and your working times as monday to friday from 8am to 7pm. Depending on your working schedule, you might want to adjust that.

# Development
To test the template with the [default properties](./src/main/g8/default.properties) run: `sbt g8`

The files will be created in `./target/g8`.

# Open questions
* Does creating into existing folders work? (e.g. modules)
* Best way to provide values, that are not strings?
  * Ask to create with defined name in README
  * Ask for $"$"$ resource in default.properties
* How to add tags?
  * Ask to defined local.tags, concatenate Name or others in, then set for all tags.
