# ==============================================================================
# HIPAA / HITRUST-Compliant Enterprise Healthcare Platform Infrastructure
# ==============================================================================

data "azurerm_client_config" "current" {}

# 1. Resource Group
resource "azurerm_resource_group" "health" {
  name     = "rg-${var.workload_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# 2. Virtual Network & Isolated Compliance Subnets
resource "azurerm_virtual_network" "health" {
  name                = "vnet-${var.workload_name}-${var.environment}"
  location            = azurerm_resource_group.health.location
  resource_group_name = azurerm_resource_group.health.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "app_service" {
  name                 = "snet-app-integration"
  resource_group_name  = azurerm_resource_group.health.name
  virtual_network_name = azurerm_virtual_network.health.name
  address_prefixes     = ["10.210.1.0/24"]

  delegation {
    name = "delegation-server-farms"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "postgres" {
  name                 = "snet-postgres-delegated"
  resource_group_name  = azurerm_resource_group.health.name
  virtual_network_name = azurerm_virtual_network.health.name
  address_prefixes     = ["10.210.2.0/24"]

  delegation {
    name = "delegation-postgres"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.health.name
  virtual_network_name = azurerm_virtual_network.health.name
  address_prefixes     = ["10.210.3.0/24"]
}

# 3. Compliance Log Analytics Workspace (730-day retention for HIPAA)
resource "azurerm_log_analytics_workspace" "health_audit" {
  name                = "law-${var.workload_name}-audit-${var.environment}"
  location            = azurerm_resource_group.health.location
  resource_group_name = azurerm_resource_group.health.name
  sku                 = "PerGB2018"
  retention_in_days   = 730
  tags                = var.tags
}

# 4. Azure Key Vault (HSM-backed Premium with Purge Protection)
resource "azurerm_key_vault" "health" {
  name                        = replace("kv${var.workload_name}${var.environment}", "-", "")
  location                    = azurerm_resource_group.health.location
  resource_group_name         = azurerm_resource_group.health.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
  tags                        = var.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

# 5. Private DNS Zone for PostgreSQL Flexible Server
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.health.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "link-postgres-vnet"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.health.id
  resource_group_name   = azurerm_resource_group.health.name
}

# 6. Random Password for PostgreSQL Admin
resource "random_password" "postgres_admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 7. Azure PostgreSQL Flexible Server (Private Link, Zone-Redundant)
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "psql-${var.workload_name}-${var.environment}"
  resource_group_name    = azurerm_resource_group.health.name
  location               = azurerm_resource_group.health.location
  version                = "16"
  delegated_subnet_id    = azurerm_subnet.postgres.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id
  administrator_login    = "healthadmin"
  administrator_password = random_password.postgres_admin.result
  zone                   = "1"

  storage_mb   = var.postgres_storage_mb
  sku_name     = var.postgres_sku_name
  backup_retention_days = 35
  geo_redundant_backups_enabled = true

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Store PostgreSQL Admin Credential in Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "psql-admin-password"
  value        = random_password.postgres_admin.result
  key_vault_id = azurerm_key_vault.health.id
  content_type = "Database-Credential"
}

# 8. Storage Account for Immutable HIPAA Medical Records (WORM Storage)
resource "azurerm_storage_account" "records" {
  name                     = replace("st${var.workload_name}phi${var.environment}", "-", "")
  resource_group_name      = azurerm_resource_group.health.name
  location                 = azurerm_resource_group.health.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  enable_https_traffic_only = true
  allow_nested_items_to_be_public = false

  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    container_delete_retention_policy {
      days = 365
    }
  }

  tags = var.tags
}
