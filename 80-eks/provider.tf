terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "6.0"
        }
    }
    backend "s3" {
        bucket = "mahis3buckets"
        key = "roboshop-dev-eks"
        region = "us-east-1"
        encrypt = true
        use_lockfile = true
    }
}

provider "aws" {
    region = "us-east-1"
}