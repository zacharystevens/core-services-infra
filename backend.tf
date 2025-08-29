terraform {
  backend "s3" {
    bucket         = "core-services-infra-terraform-state-ii9pq507"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "core-services-infra-terraform-locks-ii9pq507"
    encrypt        = true
  }
}
