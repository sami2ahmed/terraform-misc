# running this will create the following, you can validate this as well by running "terraform plan" 
1. a service account,"app-producer", which will be used for producing to an existing topic "my-topic"
2. an ACL, "app-producer-write-on-topic" associated with app-producer SA to allow writing to "my-topic"
3. an api key/secret pai, "app-producer-kafka-api-key", will be associated with "app-producer" SA  