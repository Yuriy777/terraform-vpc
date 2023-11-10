variable "availability_zone" {
  type        = string
  default     = "us-west-2a"
  description = "Main availability zone"
}

variable "vpc_cidr" {
  type        = string
  default     = "192.168.0.0/16"
  description = "Main VPC cidr block"
}

variable "ami-id" {
  type = string
  default = "ami-0efcece6bed30fd98"
  description = "Main ami id"
}