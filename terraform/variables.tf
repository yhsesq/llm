variable "aws_region" {
  default = "us-west-2"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami_id" {
  default = "ami-0991721486ed52a2c"  # Ubuntu AMI ID
}

variable "key_name" {
  default = "my-key-pair"  # SSH key name
}

variable "github_repo" {
  default = "https://github.com/yhsesq/llm"  # GitHub repository URL
}

