# Variáveis que irei chamar no main
variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "credential_file" {
  type = string
  default = .aws/credentials
}
