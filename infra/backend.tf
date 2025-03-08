terraform {
  backend "s3" {
    bucket         = "nsh-usecase1"
    key            = "env:/dev/uc7/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
  }
}