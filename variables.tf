variable "environment" {
  description = "Target deployment environment"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for Healthcare platform deployment"
  type        = string
  default     = "eastus"
}

variable "workload_name" {
  description = "Platform or service identifier"
  type        = string
  default     = "health-core"
}

variable "vnet_address_space" {
  description = "Virtual network address space for healthcare platform"
  type        = list(string)
  default     = ["10.210.0.0/16"]
}

variable "postgres_sku_name" {
  description = "Azure PostgreSQL Flexible Server SKU"
  type        = string
  default     = "GP_Standard_D4ds_v5"
}

variable "postgres_storage_mb" {
  description = "Storage capacity for PostgreSQL Flexible Server in MB"
  type        = number
  default     = 131072 # 128 GB
}

variable "tags" {
  description = "Compliance and governance tagging"
  type        = map(string)
  default = {
    Industry            = "Healthcare"
    Compliance          = "HIPAA-HITRUST-SOC2"
    DataClassification  = "Protected-Health-Information-PHI"
    Environment         = "Production"
    ManagedBy           = "Terraform"
  }
}
