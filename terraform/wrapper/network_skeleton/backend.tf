terraform {
  backend "s3" {
    bucket         = "snaatak-p14-tfstatefiles"
    key            = "env/dev/modules/network-skeleton/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "snaatak-p14-tf-statelock"
  }
}