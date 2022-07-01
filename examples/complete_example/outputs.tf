output "node_config" {
  value = module.chainlink_node.node_config
}

output "subnet_mapping" {
  value = module.chainlink_node.subnet_mapping
}

output "nlb_endpoint" {
  value = module.chainlink_node.nlb_endpoint
}
