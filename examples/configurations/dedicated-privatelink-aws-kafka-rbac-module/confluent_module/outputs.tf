output "environment_id" {
  description = "The ID of the Environment that the Kafka cluster belongs to of the form 'env-'"
  value       = confluent_environment.staging.id
}

output "kafka_cluster_id" {
  description = "The ID of the Kafka cluster of the form 'lkc-'"
  value       = confluent_kafka_cluster.dedicated.id
}