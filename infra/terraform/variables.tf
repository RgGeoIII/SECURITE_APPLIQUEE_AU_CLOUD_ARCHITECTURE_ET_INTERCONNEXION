variable "aws_region" {
  type        = string
  description = "Region AWS"
  default     = "eu-west-3"
}

variable "vpc_id" {
  type        = string
  description = "ID du VPC par defaut"
}

variable "vm_image" {
  type        = string
  description = "AMI pour les instances"
}

variable "vm_instance_type" {
  type        = string
  description = "Type d instance"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Nom de la paire de cles EC2"
  default     = "cle-xavier"
}

variable "my_ip" {
  type        = string
  description = "Votre IP publique en /32"
  default     = "82.96.161.255/32"
}

variable "student_id" {
  type        = number
  description = "Numero d etudiant (0-99) : noms et CIDR uniques"
  default     = 27
}
