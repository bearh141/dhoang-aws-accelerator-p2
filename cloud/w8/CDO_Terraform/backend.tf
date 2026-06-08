terraform {
  backend "s3" {
    bucket         = "w8-cdo-webapp-tfstate-180273188579-ap-southeast-1"
    key            = "w8/cdo-terraform/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "w8-cdo-webapp-tf-lock"
    encrypt        = true
  }
}
