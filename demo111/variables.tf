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
  default     = "env-d2m7y"
}

variable "kafka_cluster_id" {
  description = "The ID of the Kafka cluster"
  type        = string
  default     = "lkc-w7dmgm"
}

variable "subscription_id" {
  description = "The Azure subscription ID where your VNet exists"
  type        = string
  default     = "54ff81a0-e7f6-4919-9053-4cdd1c5f5ae1"
}

variable "tenant_id" {
  description = "The Azure tenant ID in which Subscription exists"
  type        = string
  default     = "0893715b-959b-4906-a185-2789e1ead045"
}