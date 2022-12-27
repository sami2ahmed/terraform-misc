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

// importing the SA used for topic creation of "my-topic"
resource "confluent_api_key" "topic-creator" {
  display_name = "topic-creator"
  owner {
    id          = "sa-jv5kxw"
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

// note it is suggested that shared services team creates all service accounts as OrganizationAdmin role is currently required for SA creation
resource "confluent_service_account" "app-producer" {
  display_name = "app-producer"
  description  = "Service account to produce to 'my-topic' topic of the Kafka cluster"
}

// creating api keys unique to the app-producer SA 
resource "confluent_api_key" "app-producer-kafka-api-key" {
  display_name = "app-producer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-producer' service account"
  owner {
    id          = confluent_service_account.app-producer.id
    api_version = confluent_service_account.app-producer.api_version
    kind        = confluent_service_account.app-producer.kind
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

// pulling in info about the topic created in "topic_creation_SA"
data "confluent_kafka_topic" "my-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  topic_name = "my-topic"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  credentials {
   key = data.confluent_api_key.topic-creator.confluent_api_key.key
   secret = data.confluent_api_key.topic-creator.confluent_api_key.secret
 }
}

resource "confluent_kafka_acl" "app-producer-write-on-topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = data.confluent_kafka_topic.my-topic.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-producer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-producer-kafka-api-key.id
    secret = confluent_api_key.app-producer-kafka-api-key.secret
  }
}
