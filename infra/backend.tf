terraform {
  backend "s3" {
    bucket         = "akired"
    key            = "env:/dev/uc/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
  }
}
