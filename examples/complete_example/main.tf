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
      TF_VERSION  = "1.1.7"
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
resource "aws_secretsmanager_secret" "keystore" {
  name        = "${local.project}/${local.environment}/node/keystore_password"
  description = "Keystore password for ${local.project}-${local.environment} project"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "api" {
  name        = "${local.project}/${local.environment}/node/api_credentials"
  description = "API credentials for ${local.project}-${local.environment} project"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "db" {
  name        = "${local.project}/${local.environment}/node/database_url"
  description = "API credentials for ${local.project}-${local.environment} project"
  recovery_window_in_days = 0
}

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

  keystore_password_secret_arn = aws_secretsmanager_secret.keystore.arn
  api_credentials_secret_arn   = aws_secretsmanager_secret.api.arn
  database_url_secret_arn      = aws_secretsmanager_secret.db.arn

  node_version        = "1.5.1"
  task_cpu            = 1024
  task_memory         = 2048
  chainlink_node_port = 14666
  chainlink_ui_port   = 6688
  subnet_mapping      = {
    "${module.vpc.azs[0]}" = {
      ip            = aws_eip.chainlink_p2p[module.vpc.azs[0]].public_ip
      subnet_id     = module.vpc.public_subnets[0]
      allocation_id = aws_eip.chainlink_p2p[module.vpc.azs[0]].id
    }
    "${module.vpc.azs[1]}" = {
      ip            = aws_eip.chainlink_p2p[module.vpc.azs[1]].public_ip
      subnet_id     = module.vpc.public_subnets[1]
      allocation_id = aws_eip.chainlink_p2p[module.vpc.azs[1]].id
    }
  }

  node_config = {
    OOT                                 = "/chainlink"
    LOG_LEVEL                           = "info"
    ETH_CHAIN_ID                        = "4"
    MIN_OUTGOING_CONFIRMATIONS          = "2"
    MINIMUM_CONTRACT_PAYMENT_LINK_JUELS = "1000000"
    LINK_CONTRACT_ADDRESS               = "0x01BE23585060835E02B77ef475b0Cc51aA1e0709"
    ALLOW_ORIGINS                       = "*"
    CHAINLINK_TLS_PORT                  = "0"
    SECURE_COOKIES                      = "false"
    FEATURE_OFFCHAIN_REPORTING          = "true"
    OCR_KEY_BUNDLE_ID                   = "61ab53fcf1fb783715a750920353522b2c8cb1494334bdc166945952baa598d9"
    P2P_PEER_ID                         = "p2p_12D3KooWMqVVtFhRxVfDHnXBzHviPiPVo3MTQq5TwvbPoxsoxmFJ"
    OCR_TRANSMITTER_ADDRESS             = "0xc11eDFd7Dd359492A686C2f27F66156CBb155D92"
    P2P_BOOTSTRAP_PEERS                 = "/dns4/rinkeby-bootstrap.dextrac.com/tcp/1100/p2p/12D3KooWFto8Fx141Kixn2JbfGXJWpt8U1B55oBQtsNZWRmyiq1D"
    DATABASE_LOCKING_MODE               = "lease"
  }
}

# Example: allow access to 6688 port of NLB to grab prometheus metrics (do not use for UI login without TLS enabled)
# resource "aws_security_group_rule" "ingress_allow_ui" {
#   type        = "ingress"
#   from_port   = "6688"
#   to_port     = "6688"
#   protocol    = "tcp"
#   cidr_blocks = [var.your]

#   security_group_id = module.chainlink_node.nlb_security_group_id
# }
