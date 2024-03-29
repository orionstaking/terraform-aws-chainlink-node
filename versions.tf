terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.2.3"
    }
  }
}
