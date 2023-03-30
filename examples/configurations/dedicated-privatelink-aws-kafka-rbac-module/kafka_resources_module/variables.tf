variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "kafka_cluster_id" {
  description = "The ID of the Kafka cluster of the form 'lkc-'"
  type        = string
}

variable "environment_id" {
  description = "The ID of the Environment that the Kafka cluster belongs to of the form 'env-'"
  type        = string
}