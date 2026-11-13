output "env_vars" {
  description = "Chainlink node configuration environment variables"
  value       = local.env_vars
}

output "subnet_mapping" {
  description = "A map of values required to enable failover between AZs"
  value       = var.subnet_mapping
}

output "nlb_endpoint" {
  description = "NLB endpoint for the Chainlink node UI. Pass operator CIDRs in ingress_whitelist. Set allow_ui_from_vpc to also allow the VPC CIDR."
  value       = "${aws_lb.this.dns_name}:6688"
}

output "validate_task_definition_family" {
  description = "Family of the Fargate task that runs chainlink node validate."
  value       = aws_ecs_task_definition.validate.family
}

output "nlb_security_group_id" {
  description = "ID of the node task security group. ingress_whitelist adds its rules here."
  value       = aws_security_group.this.id
}
