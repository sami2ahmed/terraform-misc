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
  description = "The ID of a Kafka cluster"
  type        = string
}

variable "environment_id" {
  description = "The ID of an Environment where Kafka cluster exists"
  type        = string
}