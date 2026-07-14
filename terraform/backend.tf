terraform {
  backend "s3" {
    bucket         = "royal-hotel-tf-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "royal-hotel-tf-locks"
    encrypt        = true
  }
}
