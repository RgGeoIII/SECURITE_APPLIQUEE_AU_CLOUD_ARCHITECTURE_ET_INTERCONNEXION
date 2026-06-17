variable "student_id" {
  description = "Numero d etudiant (0-99)"
  type        = number
  default     = 50
}

variable "key_name" {
  description = "Nom de la paire de cles EC2"
  type        = string
  default     = "cle-td-geogeo"
}