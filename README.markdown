A [Giter8][g8] template for ...!

# Template license
Written in 2021 by Alexander Kogan alexander.kogan@spaceteams.de

To the extent possible under law, the author(s) have dedicated all copyright and related
and neighboring rights to this template to the public domain worldwide.
This template is distributed without any warranty. See <http://creativecommons.org/publicdomain/zero/1.0/>.

[g8]: http://www.foundweekends.org/giter8/

# Properties
| Name                        | Description |
|-----------------------------|-------------|
|**addBoilerplate & region**  | If addBoilerplate is true, a main.tf will be created with the region.|
|**registrationToken**        | Needed to register the GitLab runner to a repository. You can get it in a GitLab repository from *Settings -> CI/CD -> Runners -> Set up a specific runner manually*. It is added by a .tfvars file, so that you can encrypt it for pushing it to a repository with git-crypt for example.|
|**vpcId & internetGatewayId**| VPC and internet gateway, that the runner should use. To enter Terraform outputs, you can use for example `$"$"${data.vpc_id}` to set the local as `"${data.vpc_id}"` or you can replace them afterwards.|

# Development
To test the template with the [default properties](./src/main/g8/default.properties) run: `sbt g8`

The files will be created in `./target/g8`.

# TODO
* Does creating into existing folders work? (e.g. modules)