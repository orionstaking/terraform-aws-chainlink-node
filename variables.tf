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
  description = "ARN of the Secrets Manager Secret in the same AWS account and Region that contains the keystore password for the chainlink node. Value of AWS SM object must be base64 encoded"
  type        = string
}

variable "api_credentials_secret_arn" {
  description = "ARN of the Secrets Manager Secret in the same AWS account and Region that contains the API credentials for the chainlink node. Value of AWS SM object must be base64 encoded"
  type        = string
}

variable "database_url_secret_arn" {
  description = "ARN of the Secrets Manager Secret in the same AWS account and Region that contains the database URL for the chainlink node. Value of AWS SM object must be base64 encoded"
  type        = string
}

variable "chainlink_p2p_networking_stack" {
  description = "P2P_NETWORKING_STACK from the chainlink OCR node config. More info here: https://docs.chain.link/chainlink-nodes/configuration-variables/#p2p_networking_stack"
  type        = string

  validation {
    condition     = contains(["V1", "V1V2", "V2"], var.chainlink_p2p_networking_stack)
    error_message = "Valid values for var: chainlink_p2p_networking_stack are (V1, V1V2, V2)."
  }
}

variable "chainlink_node_port_p2pv1" {
  description = "P2P_ANNOUNCE_PORT from the chainlink OCR node config. Required if chainlink_p2p_networking_stack set to `V1` or `V1V2`. More info here: https://docs.chain.link/docs/configuration-variables/#networking-stack-v1"
  type        = number
  default     = null
}

variable "chainlink_node_port_p2pv2" {
  description = "Port that will be used in P2PV2_ANNOUNCE_ADDRESSES and P2PV2_LISTEN_ADDRESSES env variables from chainlink OCR node config. Required if chainlink_p2p_networking_stack set to `V1V2` or `V2`. More info here: https://docs.chain.link/chainlink-nodes/configuration-variables/#networking-stack-v2"
  type        = number
  default     = null
}

variable "chainlink_ui_port" {
  description = "CHAINLINK_PORT from the chainlink OCR node config. More info here: https://docs.chain.link/docs/configuration-variables/#chainlink_port"
  default     = 6688
  type        = number
}

variable "chainlink_listen_ip" {
  description = "P2P_LISTEN_IP from chainlink OCR node config. Will be used in both V1 and V2 networking stack if enabled. More info here: https://docs.chain.link/chainlink-nodes/configuration-variables/#networking-stack-v1"
  default     = "0.0.0.0"
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

# TLS configutation
variable "tls_ui_enabled" {
  description = "Defines if TLS configuration to access Chainlink Node UI should be enabled"
  type        = bool
  default     = false
}

variable "tls_type" {
  description = "Defines TLS configuration. Set to `import` to import any existing TLS cert and key. It could be self-signed and created by Let's Encrypt. See more info here: https://docs.chain.link/chainlink-nodes/enabling-https-connections. AWS ACM ('acm') isn't supported yet."
  type        = string
  default     = "import"
}

variable "tls_cert_secret_arn" {
  description = "ARN of the Secrets Manager Secret in the same AWS account and Region that contains the TLS certificate. Required when `tls_ui_enabled`=`true` and `tls_type`=`import`. Value of AWS SM object must be base64 encoded"
  type        = string
  default     = ""
}

variable "tls_key_secret_arn" {
  description = "ARN of the Secrets Manager Secret in the same AWS account and Region that contains the TLS key. Required when `tls_ui_enabled`=`true` and `tls_type`=`import`. Value of AWS SM object must be base64 encoded"
  type        = string
  default     = ""
}

variable "tls_chainlink_ui_port" {
  description = "CHAINLINK_TLS_PORT from the chainlink OCR node config. More info here: https://docs.chain.link/chainlink-nodes/configuration-variables#chainlink_tls_port"
  type        = number
  default     = 6689
}
