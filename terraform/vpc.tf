# Public subnets only, no NAT gateway (~$32/month saved). Nodes get public
# IPs but stay locked down by the cluster security groups. Fine for a
# short-lived demo cluster; use private subnets + NAT for anything real.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs            = local.azs
  public_subnets = ["10.0.0.0/20", "10.0.16.0/20"]

  enable_nat_gateway      = false
  enable_dns_support      = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  # Lets the Istio Gateway's LoadBalancer Service place its NLB here.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = local.tags
}
