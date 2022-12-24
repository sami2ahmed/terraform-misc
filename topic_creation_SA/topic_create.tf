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

// 'topic-creator' service account is required in this configuration to create 'my-topic' topic and grant ACLs
// to 'app-producer' and 'app-consumer' service accounts.
resource "confluent_service_account" "topic-creator" {
  display_name = "topic-creator"
  description  = "Service account to manage my Kafka cluster"
}

resource "confluent_role_binding" "topic-creator-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.topic-creator.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = data.confluent_kafka_cluster.basic.rbac_crn
}

resource "confluent_api_key" "topic-creator-kafka-api-key" {
  display_name = "topic-creator-kafka-api-key"
  description  = "Kafka API Key that is owned by 'topic-creator' service account"
  owner {
    id          = confluent_service_account.topic-creator.id
    api_version = confluent_service_account.topic-creator.api_version
    kind        = confluent_service_account.topic-creator.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.basic.id
    api_version = data.confluent_kafka_cluster.basic.api_version
    kind        = data.confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_kafka_cluster.basic.environment[0].id
    }
  }

  # The goal is to ensure that confluent_role_binding.topic-creator-kafka-cluster-admin is created before
  # confluent_api_key.topic-creator-kafka-api-key is used to create instances of
  # confluent_kafka_topic, confluent_kafka_acl resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.topic-creator-kafka-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    confluent_role_binding.topic-creator-kafka-cluster-admin
  ]
}

resource "confluent_kafka_topic" "my-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  topic_name         = "my-topic"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  partitions_count   = 4
credentials {
   key = confluent_api_key.topic-creator-kafka-api-key.id
   secret = confluent_api_key.topic-creator-kafka-api-key.secret
 }
}
