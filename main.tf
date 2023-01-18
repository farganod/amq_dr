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

resource "null_resource" "execute" {
  depends_on = [
    aws_mq_broker.primary,
    aws_mq_broker.secondary
  ]
  provisioner "local-exec" {
    command = "py federate.py ${var.user} ${var.password} ${aws_mq_broker.secondary.instances.0.console_url} ${aws_mq_broker.primary.instances.0.endpoints.0}"
  }

}
