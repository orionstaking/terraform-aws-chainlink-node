output "node_config" {
  description = "Chainlink node configuration environment variables"
  value       = local.node_config
}

output "subnet_mapping" {
  description = "A map of values required to enable failover between AZs"
  value       = var.subnet_mapping
}

output "nlb_endpoint" {
  description = "NLB endpoint to accsess Chainlink Node UI. UI port is open only to the VPC CIDR block, in order to access the UI it's required to open SSH tunnel to any available host/bastion in the VPC. More info in Readme.md"
  value       = "${aws_lb.this.dns_name}:6688"
}

output "nlb_security_group_id" {
  description = "ID of security group attached to NLB. It's possible to use it to configure additional sg inbound rules"
  value       = aws_security_group.this.id
}
