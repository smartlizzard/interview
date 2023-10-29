terraform {
  backend "s3" {
    bucket = "tenanttfstate"
    key    = "tenant/tfstate"
    region = "us-east-1"
  }
}