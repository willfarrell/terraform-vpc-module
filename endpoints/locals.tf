data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  env     = terraform.workspace
  region  =   data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  
  name    = var.name
  tags    = merge(
    {
      "TerraformModule" = "@willfarrell/terraform-vpc-module/endpoints"
    },
    var.tags
  )
  
  gateways = ["s3","dynamodb"]
  
}
