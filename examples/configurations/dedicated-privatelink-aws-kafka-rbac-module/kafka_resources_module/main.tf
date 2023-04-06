terraform {
  required_version = ">= 0.14.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.37.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

data "confluent_kafka_cluster" "dedicated" {
  id = var.kafka_cluster_id
  
  environment {
    id = var.environment_id
  }
}

// 'app-mngr' service account is required in this configuration to create 'orders' topic and assign roles
// to 'app-prdcr' and 'app-cnsmr' service accounts.
resource "confluent_service_account" "app-mngr" {
  display_name = "app-mngr"
  description  = "Service account to manage 'inventory' Kafka cluster"
}

resource "confluent_role_binding" "app-mngr-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-mngr.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = data.confluent_kafka_cluster.dedicated.rbac_crn
}

resource "confluent_api_key" "app-mngr-kafka-api-key" {
  display_name = "app-mngr-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-mngr' service account"

  # Set optional `disable_wait_for_ready` attribute (defaults to `false`) to `true` if the machine where Terraform is not run within a private network
  # disable_wait_for_ready = true

  owner {
    id          = confluent_service_account.app-mngr.id
    api_version = confluent_service_account.app-mngr.api_version
    kind        = confluent_service_account.app-mngr.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.dedicated.id
    api_version = data.confluent_kafka_cluster.dedicated.api_version
    kind        = data.confluent_kafka_cluster.dedicated.kind

    environment {
      id = var.environment_id
    }
  }
}

// Provisioning Kafka Topics requires access to the REST endpoint on the Kafka cluster
// If Terraform is not run from within the private network, this will not work
resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.dedicated.id
  }
  topic_name    = "orders"
  rest_endpoint = data.confluent_kafka_cluster.dedicated.rest_endpoint
  credentials {
    key    = confluent_api_key.app-mngr-kafka-api-key.id
    secret = confluent_api_key.app-mngr-kafka-api-key.secret
  }
}

resource "confluent_service_account" "app-cnsmr" {
  display_name = "app-cnsmr"
  description  = "Service account to consume from 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_api_key" "app-cnsmr-kafka-api-key" {
  display_name = "app-cnsmr-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-cnsmr' service account"

  # Set optional `disable_wait_for_ready` attribute (defaults to `false`) to `true` if the machine where Terraform is not run within a private network
  # disable_wait_for_ready = true

  owner {
    id          = confluent_service_account.app-cnsmr.id
    api_version = confluent_service_account.app-cnsmr.api_version
    kind        = confluent_service_account.app-cnsmr.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.dedicated.id
    api_version = data.confluent_kafka_cluster.dedicated.api_version
    kind        = data.confluent_kafka_cluster.dedicated.kind

    environment {
      id = var.environment_id
    }
  }
}

resource "confluent_role_binding" "app-prdcr-developer-write" {
  principal   = "User:${confluent_service_account.app-prdcr.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_kafka_cluster.dedicated.rbac_crn}/kafka=${data.confluent_kafka_cluster.dedicated.id}/topic=${confluent_kafka_topic.orders.topic_name}"
}

resource "confluent_service_account" "app-prdcr" {
  display_name = "app-prdcr"
  description  = "Service account to produce to 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_api_key" "app-prdcr-kafka-api-key" {

  # Set optional `disable_wait_for_ready` attribute (defaults to `false`) to `true` if the machine where Terraform is not run within a private network
  # disable_wait_for_ready = true

  display_name = "app-prdcr-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-prdcr' service account"
  owner {
    id          = confluent_service_account.app-prdcr.id
    api_version = confluent_service_account.app-prdcr.api_version
    kind        = confluent_service_account.app-prdcr.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.dedicated.id
    api_version = data.confluent_kafka_cluster.dedicated.api_version
    kind        = data.confluent_kafka_cluster.dedicated.kind

    environment {
      id = var.environment_id
    }
  }
}

// Note that in order to consume from a topic, the principal of the consumer ('app-cnsmr' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
resource "confluent_role_binding" "app-cnsmr-developer-read-from-topic" {
  principal   = "User:${confluent_service_account.app-cnsmr.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_kafka_cluster.dedicated.rbac_crn}/kafka=${data.confluent_kafka_cluster.dedicated.id}/topic=${confluent_kafka_topic.orders.topic_name}"
}

resource "confluent_role_binding" "app-cnsmr-developer-read-from-group" {
  principal = "User:${confluent_service_account.app-cnsmr.id}"
  role_name = "DeveloperRead"
  // The existing value of crn_pattern's suffix (group=confluent_cli_consumer_*) are set up to match Confluent CLI's default consumer group ID ("confluent_cli_consumer_<uuid>").
  // https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/confluent_kafka_topic_consume.html
  // Update it to match your target consumer group ID.
  crn_pattern = "${data.confluent_kafka_cluster.dedicated.rbac_crn}/kafka=${data.confluent_kafka_cluster.dedicated.id}/group=confluent_cli_consumer_*"
}

