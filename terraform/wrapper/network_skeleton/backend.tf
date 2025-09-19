terraform {
  backend "s3" {
    bucket         = "yuvraj-opstree"
    key            = "modules/network-skeleton/terraform.tfstate"
    region         = "ap-northeast-1"
    use_lockfile  = true
  }
}
