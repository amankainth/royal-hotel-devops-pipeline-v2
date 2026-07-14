terraform {
  backend "s3" {
    bucket       = "royal-hotel-tf-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
