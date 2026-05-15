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
  description = "Contraseña root para MySQL"
  type        = string
  sensitive   = true
}
variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "despachodb"
}