terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 2.32.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.37.0"
    }
  }
}

data "confluent_kafka_cluster" "dedicated" {
  id = var.kafka_cluster_id
  
  environment {
    id = var.environment_id
  }
}


# https://docs.confluent.io/cloud/current/networking/private-links/aws-privatelink.html
# Set up the VPC Endpoint for AWS PrivateLink in your AWS account
# Set up DNS records to use AWS VPC endpoints
locals {
  hosted_zone = length(regexall(".glb", data.confluent_kafka_cluster.dedicated.bootstrap_endpoint)) > 0 ? replace(regex("^[^.]+-([0-9a-zA-Z]+[.].*):[0-9]+$", data.confluent_kafka_cluster.dedicated.bootstrap_endpoint)[0], "glb.", "") : regex("[.]([0-9a-zA-Z]+[.].*):[0-9]+$", data.confluent_kafka_cluster.dedicated.bootstrap_endpoint)[0]
}

data "aws_vpc" "privatelink" {
  id = var.vpc_id
}

data "aws_availability_zone" "privatelink" {
  for_each = var.subnets_to_privatelink
  zone_id  = each.key
}

locals {
  bootstrap_prefix = split(".", data.confluent_kafka_cluster.dedicated.bootstrap_endpoint)[0]
}

resource "aws_security_group" "privatelink" {
  # Ensure that SG is unique, so that this module can be used multiple times within a single VPC
  name        = "ccloud-privatelink_${local.bootstrap_prefix}_${var.vpc_id}"
  description = "Confluent Cloud Private Link minimal security group for ${data.confluent_kafka_cluster.dedicated.bootstrap_endpoint} in ${var.vpc_id}"
  vpc_id      = data.aws_vpc.privatelink.id

  ingress {
    # only necessary if redirect support from http/https is desired
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint" "privatelink" {
  vpc_id            = data.aws_vpc.privatelink.id
  service_name      = data.confluent_network.private-link.aws[0].private_link_endpoint_service
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.privatelink.id,
  ]

  subnet_ids          = [for zone, subnet_id in var.subnets_to_privatelink : subnet_id]
  private_dns_enabled = false

  depends_on = [
    data.confluent_private_link_access.aws,
  ]
}

resource "aws_route53_zone" "privatelink" {
  name = local.hosted_zone

  vpc {
    vpc_id = data.aws_vpc.privatelink.id
  }
}

resource "aws_route53_record" "privatelink" {
  count   = length(var.subnets_to_privatelink) == 1 ? 0 : 1
  zone_id = aws_route53_zone.privatelink.zone_id
  name    = "*.${aws_route53_zone.privatelink.name}"
  type    = "CNAME"
  ttl     = "60"
  records = [
    aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"]
  ]
}

locals {
  endpoint_prefix = split(".", aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"])[0]
}

resource "aws_route53_record" "privatelink-zonal" {
  for_each = var.subnets_to_privatelink

  zone_id = aws_route53_zone.privatelink.zone_id
  name    = length(var.subnets_to_privatelink) == 1 ? "*" : "*.${each.key}"
  type    = "CNAME"
  ttl     = "60"
  records = [
    format("%s-%s%s",
      local.endpoint_prefix,
      data.aws_availability_zone.privatelink[each.key].name,
      replace(aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"], local.endpoint_prefix, "")
    )
  ]
}

data "confluent_network" "private-link" {
  display_name = "pl-network"
  environment {
    id = var.environment_id
  }
}

data "confluent_private_link_access" "aws" {
  display_name = "AWS Private Link Access"
  environment {
    id = var.environment_id
  }
}