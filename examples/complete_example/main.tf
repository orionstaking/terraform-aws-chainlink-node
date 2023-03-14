locals {
  project     = "example"
  environment = "nonprod"
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Environment = local.environment
      Project     = local.project
      Chains      = "Ethereum"
      TF_MANAGED  = "true"
      TF_SERVICE  = "chainlink_node"
    }
  }
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.project}-${local.environment}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# AWS SecretsManager objects for Chainlink Node
resource "aws_secretsmanager_secret" "secrets" {
  name                    = "${local.project}/${local.environment}/node/secrets"
  description             = "TOML secrets for ${local.project}-${local.environment} in base64 format"
  recovery_window_in_days = 0
}

# For security reasons secret version could be manually specified using AWS console or cli.
# Specifying secret version (value) manually will prevent secret value from storing in terraform state.
# As an example here the secret versino will be specified using terraform.
resource "aws_secretsmanager_secret_version" "secrets" {
  secret_id     = aws_secretsmanager_secret.secrets.id
  secret_string = filebase64("secrets/secrets.toml")
}
#

# Public IP address for Chainlink P2P_ANNOUNCE_IP environement variable
resource "aws_eip" "chainlink_p2p" {
  for_each = toset(module.vpc.azs)

  tags = {
    Name = "${local.project}-${local.environment}-announce-${each.key}"
  }
}

# Chainlink Node Module
module "chainlink_node" {
  source = "../../."

  project     = local.project
  environment = local.environment

  aws_region     = "eu-west-1"
  aws_account_id = data.aws_caller_identity.current.account_id

  vpc_id              = module.vpc.vpc_id
  vpc_cidr_block      = module.vpc.vpc_cidr_block
  vpc_private_subnets = module.vpc.private_subnets

  secrets_secret_arn = aws_secretsmanager_secret.secrets.arn

  node_version = "1.11.0"
  task_cpu     = 1024
  task_memory  = 2048
  config_toml  = filebase64("config.toml")
  subnet_mapping = {
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

  route53_enabled        = true
  route53_domain_name    = "domain_name.com" # Should be equal to your Route53 Hosted Zone name
  route53_subdomain_name = "chainlink_eth"   # Will be used to create Route53 record to NLB endpoint with the following format "${var.route53_subdomain_name}.${var.route53_domain_name}"
  route53_zoneid         = "your_zoneid"     # Route53 hosted zone ID. Nameservers of your zone should be added to your domain registrar before creation. It will be used to create record to NLB and verify ACM certificate using DNS.
}

# Example: allow access to UI of NLB for login and prometheus metrics
# resource "aws_security_group_rule" "ingress_allow_ui" {
#   type        = "ingress"
#   from_port   = "443"
#   to_port     = "443"
#   protocol    = "tcp"
#   cidr_blocks = [var.your_ip_range]

#   security_group_id = module.chainlink_node.nlb_security_group_id
# }
