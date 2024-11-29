terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

# # Configure provider
# pr {
#   region  = "us-east-1"
# }