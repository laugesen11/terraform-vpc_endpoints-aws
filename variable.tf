
variable "vpc_endpoints" {
  description = "Sets up VPC endpoint"
  default     = null
  type = list(
    object({
      name                = string

      #Specify the AWS service this endpoint is for
      service_name        = string

      #The VPC this is assigned to
      vpc                 = string

      #Sets optional values
      #Valid values include:
      #  - "auto_accept" - Accept the VPC endpoint (the VPC endpoint and service need to be in the same AWS account).
      #  - "private_dns_enabled" -  (AWS services and AWS Marketplace partner services only) Whether or not to associate a private hosted zone with the specified VPC. Applicable for endpoints of type Interface.
      #  - "ip_address_type"="<ipv4|ipv6|dual stack>" - The IP address type for the endpoint. Valid values are ipv4, dualstack, and ipv6.
      #  - "security_groups"="<list of security groups>" - list of security groups to associate with this endpoint. Applicable for endpoints of type Interface. Can be security group defined here or external security group
      #  - "subnets"="<list of subnets>" - list of subnets this endpoint is for. Applicable for endpoints of type GatewayLoadBalancer and Interface. Can be for subnets defined here or externally
      #  - "route_tables"="<route table name or IDs>" - One or more route table names or IDs. Applicable for endpoints of type Gateway.
      #  - "vpc_endpoint_type"="<Gateway|Interface|GatewayLoadBalancer>" - The VPC endpoint type. Gateway, GatewayLoadBalancer, or Interface. Defaults to Gateway.
      #  - "dns_record_ip_type"="<ipv4|dualstack|service-defined|ipv6>"
      #  - "iam_policy"=<string> - either the name of the iam policy or the ID
      #  - "iam_policy_file"=<path> - read in a JSON file of an IAM policy
      #  - "tags" - tags for this VPC endpoint
      options             = map(string)
    })
  )
}

variable "route_tables" {
  description = "The route tables we can resolve route table names to"
  default = {}
  type = map
}

variable "vpcs" {
  description = "The VPCs that we can resolve VPC names to"
  default = {}
  type = map
}

variable "security_groups" {
  description = "The security groups that we can resolve VPC names to"
  default = {}
  type = map
}

