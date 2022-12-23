terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.20.0"
    }
  }
}
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

data "confluent_kafka_cluster" "basic" {
  id = "lkc-w7dmgm"
  environment {
    id = "env-d2m7y"
  }
}

# KEY CREATION
resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.TF-service-acct.id
    api_version = confluent_service_account.TF-service-acct.api_version
    kind        = confluent_service_account.TF-service-acct.kind
  }
  managed_resource {
    id          = data.confluent_kafka_cluster.basic.id
    api_version = data.confluent_kafka_cluster.basic.api_version
    kind        = data.confluent_kafka_cluster.basic.kind
    environment {
      id = data.confluent_kafka_cluster.basic.environment[0].id
    }
  }
}

resource "confluent_service_account" "TF-service-acct" {
  display_name = "TF-service-acct"
  description  = "Service account to consume from topics of 'TEST_BASIC' Kafka cluster"
}
