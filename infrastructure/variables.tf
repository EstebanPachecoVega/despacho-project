variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "despacho-project"
}

variable "key_pair_name" {
  description = "Nombre del Key Pair para la instancia EC2"
  type        = string
}

variable "db_password" {
  description = "Contraseña root para MySQL"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos a crear"
  type        = string
}