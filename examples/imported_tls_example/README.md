# Complete example deployment

How to test:
- run `aws configure` to setup aws credentials. Specify `eu-west-1` as a region.
- comment out chainlink node module in main.tf
- run `terraform plan` and `terraform apply` to create VPC, EIPs and secrets. Then update secrets value for your chainlink node in base64 encode if not updated by terraform.
- set all required variables in config.toml
- set `AnnounceIP` and `AnnounceAddresses` in config.toml according to `chainlink_p2p_ips` terraform output.
- uncomment chainlink node module in main.tf
- run `terraform plan` and `terraform apply` (approx time of creation ~10 min)
- Once test is over run `terraform destroy` (time of deletion ~3 min)
