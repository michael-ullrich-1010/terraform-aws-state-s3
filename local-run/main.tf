provider "aws" {
  region  = "eu-central-1"
  profile = "rwe_core_cicd_poc"
}

module "deploy" {
  source = "../"
}