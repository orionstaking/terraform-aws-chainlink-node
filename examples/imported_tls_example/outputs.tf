output "subnet_mapping" {
  description = "A map of values required to enable failover between AZs"
  value       = module.chainlink_node.subnet_mapping
}

output "chainlink_p2p_ips" {
  description = "A list of IP's that needs to be specified in config.toml"
  value = [
    for ip_nma in aws_eip.chainlink_p2p : ip_nma.public_ip
  ]
}

output "nlb_endpoint" {
  description = "Network Load Balancer URL that should be used to access CL node"
  value       = module.chainlink_node.nlb_endpoint
}
