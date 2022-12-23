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

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  owner {
    id          = "sa-9wj30y"
    api_version = "iam/v2"
    kind        = "ServiceAccount"
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

resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  topic_name         = "orders"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  partitions_count   = 4
credentials {
   key = "${confluent_api_key.app-manager-kafka-api-key.id}"
   secret = "${confluent_api_key.app-manager-kafka-api-key.secret}"
 }
}
