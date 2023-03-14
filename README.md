# Chainlink Node Terraform Module

Terraform module which creates AWS serverless infra for Chainlink Node:
  - AWS Fargate
  - AWS Network Load Balancer
  - AWS IAM
  - AWS CloudWatch

Terraform module for Chainlink External Adapters: [here](https://github.com/orionterra/terraform-aws-chainlink-ea)

## Architecture overview

<img src="./drawio/cl-node-orion.png" width="700">

Where:

- ![#DAE8FC](https://via.placeholder.com/15/DAE8FC/DAE8FC.png) Covered by this Chainlink Node terraform [module](https://github.com/orionterra/terraform-aws-chainlink-node)
- ![#D5E8D4](https://via.placeholder.com/15/D5E8D4/D5E8D4.png) Covered by Chainlink External Adapters terraform [module](https://github.com/orionterra/terraform-aws-chainlink-ea)
- ![#D0CEE2](https://via.placeholder.com/15/D0CEE2/D0CEE2.png) Covered by RDS community terraform [module](https://github.com/terraform-aws-modules/terraform-aws-rds-aurora)
- ![#FFE6CC](https://via.placeholder.com/15/FFE6CC/FFE6CC.png) Covered by VPC community terraform [module](https://github.com/terraform-aws-modules/terraform-aws-vpc)

## Usage

### Basic example

Full example [here](https://github.com/orionterra/terraform-aws-chainlink-node/tree/main/examples/complete_example)

```hcl
module "chainlink_node" {
  source  = "ChainOrion/chainlink-node/aws"

  project     = local.project
  environment = local.environment

  aws_region     = "eu-west-1"
  aws_account_id = data.aws_caller_identity.current.account_id

  vpc_id              = module.vpc.vpc_id
  vpc_cidr_block      = module.vpc.vpc_cidr_block
  vpc_private_subnets = module.vpc.private_subnets

  secrets_secret_arn = aws_secretsmanager_secret.secrets.arn

  # Always check latest versions
  node_version        = "1.12.0"
  task_cpu            = 1024
  task_memory         = 2048
  subnet_mapping      = {
    (module.vpc.azs[0]) = {
      ip            = aws_eip.chainlink_p2p[module.vpc.azs[0]].public_ip
      subnet_id     = module.vpc.public_subnets[0]
      allocation_id = aws_eip.chainlink_p2p[module.vpc.azs[0]].id
    }
    (module.vpc.azs[1]) = {
      ip            = aws_eip.chainlink_p2p[module.vpc.azs[1]].public_ip
      subnet_id     = module.vpc.public_subnets[1]
      allocation_id = aws_eip.chainlink_p2p[module.vpc.azs[1]].id
    }
  }

  route53_enabled = true
  route53_domain_name = "domain_name.com"
  route53_subdomain_name = "chainlink_eth"
  route53_zoneid = "your_zoneid"
}
```

## Notes

### Chainlink Node configuration

This module now supports only TOML configuration. See the [CONFIG.md](https://github.com/smartcontractkit/chainlink/blob/v1.11.0/docs/CONFIG.md) and [SECRETS.md](https://github.com/smartcontractkit/chainlink/blob/v1.11.0/docs/SECRETS.md) on GitHub to learn more.

Place your config.toml in the root of terraform directory. This module will parse and verify it. You will see an error in case of invalid config.toml configuration for this terraform module. Please see an example before proceed.

Additionally, it's possible to pass any environment variable to Fargate container using `env_vars` terraform module variable.

Check example [here](https://github.com/orionterra/terraform-aws-chainlink-node/tree/main/examples/complete_example).

### Secrets

Module is required the following AWS Secrets Manager secrets created and set:

- Secret that contain secrets.toml (base64)
- Secret that contain TLS_CERT (base64) (required when WebServer.TLS configuration exist in TOML config)
- Secret that contain TLS_KEY (base64) (required when WebServer.TLS configuration exist in TOML config)

Deploy order:

- Firstly, it's required to create and set AWS Secrets Manager objects ([example](https://github.com/orionterra/terraform-aws-chainlink-node/tree/main/examples/complete_example))
- Then, AWS ARN values of the created secrets should be specified in the module. ([example](https://github.com/orionterra/terraform-aws-chainlink-node/tree/main/examples/complete_example))

Check example [here](https://github.com/orionterra/terraform-aws-chainlink-node/tree/main/examples/complete_example).

### Failover

Chainlink Node failover is realized using `AnnounceAddresses` in P2P.V2 in your config.toml file. Please specify the same IP's as you have in `subnet_mapping` terraform variable. In case of one of AWS availability zone failure, Fargate will drain node container in one az and run a new one in another based on NLB target group health checks.

This module will check provided values and you will see an error if you specified different IP addresses. Failover is only available for `V2` or `V1V2` networking stack.

Check example with properly set `subnet_mapping` terraform module variable [here](https://github.com/orionterra/terraform-aws-chainlink-node/tree/main/examples/complete_example).

### TLS & HTTPS Support

Module support two types of configuration to secure UI connection

- AWS ACM (recommended). This option requires configured Route53 hosted zone to create records for AWS NLB and AWS ACM certificate validation. Check example [here](https://github.com/orionterra/terraform-aws-chainlink-node/tree/main/examples/complete_example).
- Imported TLS as described [here](https://docs.chain.link/chainlink-nodes/enabling-https-connections) (deprecated).This option requires providing AWS Secrets Manager ARN's with self signed TLS key and certificate. Check example with imported TLS configuration [here](https://github.com/orionterra/terraform-aws-chainlink-node/tree/main/examples/imported_tls_example).

### UI Access

By default security group connected to NLB allows only p2p connections for chainlink node.In order to access the UI it's required to add AWS security group ingress rule for required IP range or ranges. Check example [here](https://github.com/orionterra/terraform-aws-chainlink-node/tree/main/examples/complete_example)

### Notifications

It's possible to specify your own AWS SNS topic for notifications. Otherwise, module will create SNS topic for notifications. Then you should manually add subscriptions to that topic.

## Examples

Create AWS Secrets Manager objects first by commenting out the section with module. Then set secret values and uncomment module section in the example.

- [Complete example](./examples/complete_example/main.tf)
- [Imported TLS example](./examples/imported_tls_example/main.tf)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.40.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | 2.2.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.40.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.2.3 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_metric_filter.error_node_unreachable](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_metric_alarm.cpu_utilization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.log_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.memory_utilization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.node_v2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.ui](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.ui_secure](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.node_v2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.ui](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_secretsmanager_secret.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress_allow_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_allow_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_allow_node_v2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_allow_ui](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [random_string.alb_prefix_node](https://registry.terraform.io/providers/hashicorp/random/3.4.3/docs/resources/string) | resource |
| [random_string.alb_prefix_node_v2](https://registry.terraform.io/providers/hashicorp/random/3.4.3/docs/resources/string) | resource |
| [random_string.alb_prefix_ui](https://registry.terraform.io/providers/hashicorp/random/3.4.3/docs/resources/string) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [external_external.parse_config](https://registry.terraform.io/providers/hashicorp/external/2.2.3/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS account id. Used to add alarms to dashboard | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region (required for CloudWatch logs configuration) | `string` | n/a | yes |
| <a name="input_config_toml"></a> [config\_toml](#input\_config\_toml) | Base64 encoded Chainlink node configuration from config.toml | `string` | n/a | yes |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | Map of values that will be set as environment variables for Chainlink node process. By default it isn't required when using TOML configuration, but could be used to pass any environemnt variable to ECS task | `map(any)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"nonprod"` | no |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Defines whether to create CloudWatch dashboard and custom metrics or not | `bool` | `true` | no |
| <a name="input_node_image_source"></a> [node\_image\_source](#input\_node\_image\_source) | Chainlink node docker image source. This variable can be used to rewrite default image source. Used AWS registry by default. Set to `smartcontract/chainlink` to use dockerhub registry | `string` | `"public.ecr.aws/chainlink/chainlink"` | no |
| <a name="input_node_version"></a> [node\_version](#input\_node\_version) | Chainlink node version. The latest version could be found here: https://hub.docker.com/r/smartcontract/chainlink/tags | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_route53_domain_name"></a> [route53\_domain\_name](#input\_route53\_domain\_name) | Domain name that is used in your AWS Route53 hosted zone. Nameservers of your zone should be added to your domain registrar before creation. It will be used to create record to NLB and verify ACM certificate using DNS | `string` | `""` | no |
| <a name="input_route53_enabled"></a> [route53\_enabled](#input\_route53\_enabled) | Defines if AWS Route53 record and AWS ACM certificate for UI access should be created. Nameservers of your zone should be added to your domain registrar before creation. It will be used to create record to NLB and verify ACM certificate using DNS | `bool` | `false` | no |
| <a name="input_route53_subdomain_name"></a> [route53\_subdomain\_name](#input\_route53\_subdomain\_name) | Subdomain name that will be used to create Route53 record to NLB endpoint with the following format: $var.route53\_subdomain\_name.$var.route53\_domain\_name | `string` | `""` | no |
| <a name="input_route53_zoneid"></a> [route53\_zoneid](#input\_route53\_zoneid) | Route53 hosted zone id. Nameservers of your zone should be added to your domain registrar before creation. It will be used to create record to NLB and verify ACM certificate using DNS | `string` | `""` | no |
| <a name="input_secrets_secret_arn"></a> [secrets\_secret\_arn](#input\_secrets\_secret\_arn) | ARN of the Secrets Manager Secret in the same AWS account and Region that contains TOML secrets for Chainlink Node (base64 encoded). See https://github.com/smartcontractkit/chainlink/blob/v1.11.0/docs/SECRETS.md on github to learn more. | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | SNS topic arn for alerts. If not specified, module will create an empty topic and provide topic arn in the output. Then it will be possible to specify required notification method for this topic | `string` | `""` | no |
| <a name="input_subnet_mapping"></a> [subnet\_mapping](#input\_subnet\_mapping) | A map of values required to enable failover between AZs. See an example in ./examples directory | `map(any)` | n/a | yes |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | Allocated CPU for chainlink node container | `number` | `2048` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | Allocated Memory for chainlink node container | `number` | `4096` | no |
| <a name="input_tls_cert_secret_arn"></a> [tls\_cert\_secret\_arn](#input\_tls\_cert\_secret\_arn) | ARN of the Secrets Manager Secret in the same AWS account and Region that contains the TLS certificate (base64 encoded). Required when WebServer.TLS configuration exist in TOML config | `string` | `""` | no |
| <a name="input_tls_key_secret_arn"></a> [tls\_key\_secret\_arn](#input\_tls\_key\_secret\_arn) | ARN of the Secrets Manager Secret in the same AWS account and Region that contains the TLS key (base64 encoded). Required when WebServer.TLS configuration exist in TOML config | `string` | `""` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | The CIDR block of the VPC | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where Chainlink EAs should be deployed | `string` | n/a | yes |
| <a name="input_vpc_private_subnets"></a> [vpc\_private\_subnets](#input\_vpc\_private\_subnets) | VPC private subnets where Chainlink Node should be deployed (at least 2) | `list(any)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_env_vars"></a> [env\_vars](#output\_env\_vars) | Chainlink node configuration environment variables |
| <a name="output_nlb_endpoint"></a> [nlb\_endpoint](#output\_nlb\_endpoint) | NLB endpoint to accsess Chainlink Node UI. UI port is open only to the VPC CIDR block, in order to access the UI it's required to open SSH tunnel to any available host/bastion in the VPC. More info in Readme.md |
| <a name="output_nlb_security_group_id"></a> [nlb\_security\_group\_id](#output\_nlb\_security\_group\_id) | ID of security group attached to NLB. It's possible to use it to configure additional sg inbound rules |
| <a name="output_subnet_mapping"></a> [subnet\_mapping](#output\_subnet\_mapping) | A map of values required to enable failover between AZs |
<!-- END_TF_DOCS -->

## License

MIT License. See [LICENSE](https://github.com/orionterra/terraform-aws-chainlink-node/tree/main/LICENSE) for full details.

## Docs update

More about [terraform-docs](https://terraform-docs.io/user-guide/introduction/).

```bash
terraform-docs .
```
