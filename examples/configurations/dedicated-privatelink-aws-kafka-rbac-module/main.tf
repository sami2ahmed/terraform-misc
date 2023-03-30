terraform {
  required_version = ">= 0.14.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.37.0"
    }
  }
}

module "confluent" {
  source = "./confluent_module"

  confluent_cloud_api_key    = var.confluent_cloud_api_key
  confluent_cloud_api_secret = var.confluent_cloud_api_secret
}

module "dns" {
  source = "./dns_module"

  depends_on             = [module.confluent]
  aws_account_id         = var.aws_account_id
  region                 = var.region
  subnets_to_privatelink = var.subnets_to_privatelink
  vpc_id                 = var.vpc_id
}

module "kafka_resources" {
  source = "./kafka_resources_module"

  confluent_cloud_api_key    = var.confluent_cloud_api_key
  confluent_cloud_api_secret = var.confluent_cloud_api_secret

  environment_id   = module.confluent.environment_id
  kafka_cluster_id = module.confluent.kafka_cluster_id

  depends_on = [module.dns]
}