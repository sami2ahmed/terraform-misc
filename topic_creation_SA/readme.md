# running this will create the following, you can validate this as well by running "terraform plan" 
1. a topic, 'my-topic', with 4 partitions on an existing basic cluster
2. new api key/secret pair, 'topic-creator-kafka-api-key', associated with a new SA, 'topic-creator'
3. 'topic-creator' will have Cloudclusteradmin role created to enable topic creation capability 
