terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 2.32.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.37.0"
    }
  }
}

module "confluent" {
  source = "./confluent_module"

}

module "dns" {
  source = "./dns_module"
  depends_on = [module.confluent]
}

module "kafka_resources" {
  source          = "./kafka_resources_module"
  confluent_api_key = module.confluent.confluent_api_key
  depends_on      = [module.dns]
}
