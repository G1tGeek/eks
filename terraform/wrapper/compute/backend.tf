terraform {
  backend "s3" {
    bucket         = "yuvraj-opstree"
    key            = "modules/compute/terraform.tfstate"
    region         = "ap-northeast-1"
    use_lockfile  = true
  }
}
