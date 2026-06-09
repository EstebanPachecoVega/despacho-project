variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "despacho-project"
}

variable "key_pair_name" {
  description = "Nombre del Key Pair (debe existir en AWS)"
  type        = string
}

variable "db_password" {
  description = "Contrasena del usuario de aplicacion para MySQL"
  type        = string
  sensitive   = true
}

variable "db_root_password" {
  description = "Contrasena root para administracion de MySQL"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Usuario de aplicacion para MySQL"
  type        = string
  default     = "despacho_app"
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "despachodb"
}

variable "db_volume_size" {
  description = "Tamano en GiB del volumen persistente de datos de MySQL"
  type        = number
  default     = 30
}
