# Complete example deployment

How to test:
- run `aws configure` to setup aws credentials. Specify `eu-west-1` as a region.
- comment out the chainlink node module in main.tf
- run `terraform apply` to create the VPC, EIPs and secrets
- set `AnnounceAddresses` in config.toml to the Elastic IP addresses from that apply
- run `terraform apply` again so the config secret picks up the file
- uncomment the chainlink node module in main.tf
- run `terraform plan` and `terraform apply` (approx time of creation ~10 min). Plan reads the config secret for the ports.
- Once test is over run `terraform destroy` (time of deletion ~3 min)
