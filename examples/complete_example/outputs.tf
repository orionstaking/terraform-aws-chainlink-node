output "node_config" {
  description = "Chainlink node configuration environment variables"
  value       = module.chainlink_node.node_config
}

output "subnet_mapping" {
  description = "A map of values required to enable failover between AZs"
  value       = module.chainlink_node.subnet_mapping
}

output "nlb_endpoint" {
  description = "Network Load Balancer URL that should be used to access CL node"
  value       = module.chainlink_node.nlb_endpoint
}
