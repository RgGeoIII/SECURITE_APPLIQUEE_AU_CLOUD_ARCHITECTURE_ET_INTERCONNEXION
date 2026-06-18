variable "aws_region" {
  default = "eu-west-3"
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-3a", "eu-west-3b"]
}

# Subnets publics (un par AZ)
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["172.31.60.0/24", "172.31.61.0/24"]
}

# Subnets privés web (un par AZ)
variable "web_subnet_cidrs" {
  type    = list(string)
  default = ["172.31.70.0/24", "172.31.71.0/24"]
}

# Subnets privés app (un par AZ)
variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["172.31.80.0/24", "172.31.81.0/24"]
}

# Subnets privés data (un par AZ)
variable "data_subnet_cidrs" {
  type    = list(string)
  default = ["172.31.82.0/24", "172.31.83.0/24"]
}

variable "db_username" {
  default = "appuser"
}

variable "db_password" {
  description = "Mot de passe RDS"
  type        = string
  sensitive   = true
  default     = "kSzSWSJVImXblGzX"
}

variable "db_name" {
  default = "signupdb"
}

variable "key_name" {
  description = "Nom de la paire de cles EC2"
  type        = string
  default     = "cle-xavier"
}

variable "my_ip" {
  description = "Votre IP publique en /32 pour SSH"
  type        = string
  default     = "82.96.161.255/32"
}
