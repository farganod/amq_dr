output "priamary_console"{
  value = resource.aws_mq_broker.primary.instances.0.console_url 
}

output "secondary_console"{
  value = resource.aws_mq_broker.secondary.instances.0.console_url 
}

output "primary_endpoint"{
    value = resource.aws_mq_broker.primary.instances.0.endpoints.0
}