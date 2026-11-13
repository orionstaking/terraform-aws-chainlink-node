# Complete example deployment

How to test:
- run `aws configure` to setup aws credentials. Specify `eu-west-1` as a region.
- comment out the chainlink node module in main.tf
- run `terraform apply` to create the VPC, EIPs and secrets
- set `AnnounceAddresses` in config.toml to the Elastic IP addresses from that apply
- run `terraform apply` again so the config secret picks up the file
- uncomment the chainlink node module in main.tf
- run `terraform plan` and `terraform apply` (approx time of creation ~10 min). Plan reads the config secret for the ports.
- Once test is over run `terraform destroy` (time of deletion ~3 min)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.40.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.40.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_chainlink_node"></a> [chainlink\_node](#module\_chainlink\_node) | ../../. | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eip.chainlink_p2p](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_secretsmanager_secret.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_chainlink_p2p_ips"></a> [chainlink\_p2p\_ips](#output\_chainlink\_p2p\_ips) | A list of IP's that needs to be specified in config.toml |
| <a name="output_nlb_endpoint"></a> [nlb\_endpoint](#output\_nlb\_endpoint) | Network Load Balancer URL that should be used to access CL node |
| <a name="output_subnet_mapping"></a> [subnet\_mapping](#output\_subnet\_mapping) | A map of values required to enable failover between AZs |
<!-- END_TF_DOCS -->
