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

variable "keystore_password_secret_arn" {
  description = "ARN of the Secrets Manager Secret in the same AWS account and Region that contains the keystore password for the chainlink node"
  type        = string
}

variable "api_credentials_secret_arn" {
  description = "ARN of the Secrets Manager Secret in the same AWS account and Region that contains the API credentials for the chainlink node"
  type        = string
}

variable "database_url_secret_arn" {
  description = "ARN of the Secrets Manager Secret in the same AWS account and Region that contains the database URL for the chainlink node"
  type        = string
}

variable "chainlink_node_port" {
  description = "P2P_ANNOUNCE_PORT from the chainlink OCR node config. More info here: https://docs.chain.link/docs/configuration-variables/#networking-stack-v1"
  type        = number
}

variable "chainlink_ui_port" {
  description = "CHAINLINK_PORT from the chainlink OCR node config. More info here: https://docs.chain.link/docs/configuration-variables/#chainlink_port"
  default     = 6688
  type        = number
}

variable "node_version" {
  description = "Chainlink node version. The latest version could be found here: https://hub.docker.com/r/smartcontract/chainlink/tags"
  type        = string
}

variable "node_config" {
  description = "Chainlink node configuration environment variables. The full list could be found here: https://docs.chain.link/docs/configuration-variables/"
  type        = map(any)
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
