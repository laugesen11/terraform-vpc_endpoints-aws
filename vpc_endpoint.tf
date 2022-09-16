#Creates VPC Endpoints
#Dependancies:
#  - variables.tf - defines VPCs and subnet that we are assigning these endpoints to
#  Reads in:
#    - vpc_endpoints variable
#  - vpc.tf       - creates VPCs and subnets we place VPC Endpoint in

locals {
  #When setting the policy, we prioritize using an existing IAM policy over feeding in a file
  #This is why we won't use the "iam_policy_file" entry if we specify "iam_policy"
  iam_policies_to_make_from_files = {
    for item in var.vpc_endpoints: 
      item.name => item.options["iam_policy_file"] if lookup(item.options,"iam_policy",null) == null && lookup(item.options,"iam_policy_file",null) != null
  }
}

resource "aws_iam_policy" "iam_policies_from_files" {
  for_each = local.iam_policies_to_make_from_files
  description = "AWS IAM policy created for VPC endpoint named ${each.key} from file ${each.value}"
  
  policy = file(each.value)
  
  tags = {
    "VPC Endpoint Name" = each.key
    "Input file" = each.value
  }
}

locals {
  vpc_endpoints_config = { 
    for item in var.vpc_endpoints: item.name => {
      "service_name"        = item.service_name
      #See if we have an entry in the VPC module for the value of 'vpc_name_or_id'. If not, we assume this is the VPC ID itself
      "vpc_id"              = lookup(module.vpcs,item.vpc,item.vpc) 
      "auto_accept"         = lookup(item.options,"auto_accept",false)
      #Can only set this for endpoints of type "Gateway"
      "private_dns_enabled" = lower(lookup(item.options,"vpc_endpoint_type","Gateway")) == "interface" ? lookup(item.options,"private_dns_enabled",false) : null
      #Dafaults to Gateway
      "vpc_endpoint_type"   = lookup(item.options,"vpc_endpoint_type","Gateway")
      #We read in the IAM policy created locally here, or we get the IAM policy requested
      #Will add ability to resolve IAM policies from module once available
      "policy"              = lookup(aws_iam_policy.iam_policies_from_files,item.name,null) != null ? aws_iam_policy.iam_policies_from_files[item.name].id : lookup(item.options,"iam_policy",null)
      "ip_address_type"     = lookup(item.options,"ip_address_type",null)
 
      "tags"                = lookup(item.options,"tags",null) == null ? {} : {
                                for tag in split(",",item.options["tags"]):
                                  element(split("=",tag),0) => element(split("=",tag),1)
                              }
   
      "route_table_ids"     = lookup(item.options,"route_tables",null) == null ? null : [for route_table in split(",",item.options["route_tables"]): lookup(var.route_tables,route_table,null) != null ? var.route_tables[route_table].id : route_table ]
      "security_group_ids"  = lookup(item.options,"security_groups",null) == null ? null : [for security_group in split(",",item.options["security_groups"]): lookup(var.security_groups,security_group,null) != null ? var.security_groups[security_group].id : security_group ]

      #Subnet IDs are only allowed for Interface and GatewayLoadBalancer type VPC Endpoints
      "subnet_ids" = lower(lookup(item.options,"vpc_endpoint_type","Gateway")) != "gateway" && lookup(item.options,"subnets",null) != null ? [for subnet in split(",",item.options["subnets"]) : lookup(module.vpcs,item.vpc,null) == null ? subnet : (lookup(module.vpcs[item.vpc_name].subnets,subnet,null) != null ? module.vpcs[item.vpc_name].subnets[subnet].id : subnet) ] : null
    }
  }
}

#Make VPC endpoint resources
resource "aws_vpc_endpoint" "vpc_endpoints" {
  for_each            = local.vpc_endpoints_config
  service_name        = each.value.service_name
  vpc_id              = each.value.vpc_id
  auto_accept         = each.value.auto_accept
  private_dns_enabled = each.value.private_dns_enabled
  security_group_ids  = each.value.security_group_ids
  vpc_endpoint_type   = each.value.vpc_endpoint_type
  subnet_ids          = each.value.subnet_ids
  route_table_ids     = each.value.route_table_ids
  policy              = each.value.policy
  ip_address_type     = each.value.ip_address_type
  tags                = merge({"Name" = item.name},each.value.tags)
}
