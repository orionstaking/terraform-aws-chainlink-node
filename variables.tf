variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "nonprod"
}

variable "aws_region" {
  description = "AWS Region (required for CloudWatch logs configuration)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account id. Used to add alarms to dashboard"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Chainlink EAs should be deployed"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "vpc_private_subnets" {
  description = "VPC private subnets where Chainlink Node should be deployed (at least 2)"
  type        = list(any)
}

variable "subnet_mapping" {
  description = "A map of values required to enable failover between AZs. See an example in ./examples directory"
  type        = map(any)
}

variable "monitoring_enabled" {
  description = "Defines whether to create CloudWatch dashboard and custom metrics or not"
  default     = true
  type        = bool
}

variable "sns_topic_arn" {
  description = "SNS topic arn for alerts. If not specified, module will create an empty topic and provide topic arn in the output. Then it will be possible to specify required notification method for this topic"
  default     = ""
  type        = string
}

variable "node_version" {
  description = "Chainlink node version. The latest version could be found here: https://hub.docker.com/r/smartcontract/chainlink/tags"
  type        = string
}

variable "node_image_source" {
  description = "Chainlink node docker image source. This variable can be used to rewrite default image source. Used AWS registry by default. Set to `smartcontract/chainlink` to use dockerhub registry"
  default     = "public.ecr.aws/chainlink/chainlink"
  type        = string
}

variable "env_vars" {
  description = "Map of values that will be set as environment variables for Chainlink node process. By default it isn't required when using TOML configuration, but could be used to pass any environemnt variable to ECS task"
  type        = map(any)
  default     = {}
}

variable "task_cpu" {
  description = "Allocated CPU for chainlink node container"
  type        = number
  default     = 2048
}

variable "task_memory" {
  description = "Allocated Memory for chainlink node container"
  type        = number
  default     = 4096
}

variable "otel_config" {
  description = "Base64 encoded OpenTelemetry collector configuration"
  type        = string
}

variable "config_plain_secret_arn" {
  description = "ARN of the Secrets Manager secret that holds config.toml. The node task reads this secret directly. Plan reads it only to learn the ports. A separate task definition runs chainlink node validate."
  type        = string
}

variable "secrets_plain_secret_arn" {
  description = "ARN of the Secrets Manager secret that holds secrets.toml. The node task reads this secret directly. See https://github.com/smartcontractkit/chainlink/blob/v1.11.0/docs/SECRETS.md"
  type        = string
}

variable "route53_enabled" {
  description = "Defines if AWS Route53 record and AWS ACM certificate for UI access should be created. Nameservers of your zone should be added to your domain registrar before creation. It will be used to create record to NLB and verify ACM certificate using DNS"
  type        = bool
  default     = false
}

variable "route53_zoneid" {
  description = "Route53 hosted zone id. Nameservers of your zone should be added to your domain registrar before creation. It will be used to create record to NLB and verify ACM certificate using DNS"
  type        = string
  default     = ""
}

variable "route53_domain_name" {
  description = "Domain name that is used in your AWS Route53 hosted zone. Nameservers of your zone should be added to your domain registrar before creation. It will be used to create record to NLB and verify ACM certificate using DNS"
  type        = string
  default     = ""
}

variable "route53_subdomain_name" {
  description = "Subdomain name that will be used to create Route53 record to NLB endpoint with the following format: $var.route53_subdomain_name.$var.route53_domain_name"
  type        = string
  default     = ""
}
