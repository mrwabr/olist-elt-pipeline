variable "bucket_name" {
  description = "Nom (unique globalement) du bucket S3 servant de data lake (zone RAW/bronze)."
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement (dev, prod, ...)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags communs appliqués aux ressources."
  type        = map(string)
  default     = {}
}

variable "raw_prefix" {
  description = "Préfixe (dossier logique) de la zone bronze dans le bucket."
  type        = string
  default     = "raw"
}

variable "force_destroy" {
  description = "Autorise la suppression du bucket même s'il contient des objets (utile en dev)."
  type        = bool
  default     = true
}