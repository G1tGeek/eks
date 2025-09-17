terraform {
  backend "s3" {
    bucket         = "yuvraj-opstree"
    key            = "modules/network-skeleton/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "yuvraj-tf-statelock"
  }
}