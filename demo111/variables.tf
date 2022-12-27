variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "topic_name" {
  description = "The name of the topic to create"
  type        = string
  default     = "module_test"
}

variable "environment_id" {
  description = "The environment where the Kafka cluster exists"
  type        = string
  default     = "env-9k5g5v"
}

variable "kafka_cluster_id" {
  description = "The ID of the Kafka cluster"
  type        = string
  default     = "lkc-nwom9d"
}
