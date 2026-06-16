variable "aws_region" {
  type        = string
  description = "region par default"
  default     = "eu-west-3"

}

variable "vpc_id" {
  type        = string
  description = "vpc id"

}

variable "vm_image" {
  type        = string
  description = "ami for vms"

}
variable "vm_instance_type" {
  type        = string
  description = "instance type for vms"
  default     = "t3.micro"

}
variable "my_ip" {
  type        = string
  description = "Adresse IP publique autorisée pour SSH, format x.x.x.x/32"
}
