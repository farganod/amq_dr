#data to pull in the attributed for RabbitMQ engine
data "aws_mq_broker_instance_type_offerings" "engine" {
  engine_type = "RABBITMQ"
}

#deploys the Rabbit MQ cluster in the primary region
resource "aws_mq_broker" "primary" {
  broker_name = "primary"

  engine_type         = "RabbitMQ"
  engine_version      = data.aws_mq_broker_instance_type_offerings.engine.broker_instance_options.0.supported_engine_versions.0
  host_instance_type  = "mq.m5.large"
  deployment_mode     = "CLUSTER_MULTI_AZ"
  publicly_accessible = true

  user {
    username = var.user
    password = var.password
  }
}

#deploys the Rabbit MQ cluster in the secondary region
resource "aws_mq_broker" "secondary" {
  provider = aws.dr
  broker_name = "secondary"

  engine_type         = "RabbitMQ"
  engine_version      = data.aws_mq_broker_instance_type_offerings.engine.broker_instance_options.0.supported_engine_versions.0
  host_instance_type  = "mq.m5.large"
  deployment_mode     = "CLUSTER_MULTI_AZ"
  publicly_accessible = true

  user {
    username = var.user
    password = var.password
  }
}

#Creates the federation on the secondary broker to the primary
resource "rabbitmq_federation_upstream" "federation" {
  provider = rabbitmq.secondary
  depends_on = [
    aws_mq_broker.secondary
  ]
  name = "primary_federation"
  vhost = "/"

  definition {
    uri = "amqps://${var.user}:${var.password}@${split("//",aws_mq_broker.primary.instances.0.endpoints.0)[1]}"
    ack_mode = "on-confirm"
    expires = 3600000
  }
}

#Creates the policy to enable all federation upstream based on regex filter variable
resource "rabbitmq_policy" "policy" {
  provider = rabbitmq.secondary
  depends_on = [
    aws_mq_broker.secondary
  ]
  name  = "federate-pri"
  vhost = "/"

  policy {
    pattern  = var.regex
    priority = 1
    apply_to = "exchanges"

    definition = {
      federation-upstream-set = "all"
    }
  }
}

#Creates a demo queue on the secondary broker
resource "rabbitmq_queue" "demo" {
  provider = rabbitmq.secondary
  depends_on = [
    aws_mq_broker.secondary
  ]
  name  = "demo"
  vhost = "/"

  settings {
    durable     = true
    auto_delete = false
  }
}

#Binds the queue to the amq.direct exchange for demo purposes
resource "rabbitmq_binding" "bind" {
  provider = rabbitmq.secondary
  depends_on = [
    aws_mq_broker.secondary
  ]
  source           = "amq.direct"
  vhost            = "/"
  destination      = "${rabbitmq_queue.demo.name}"
  destination_type = "queue"
  routing_key      = "#"
}
