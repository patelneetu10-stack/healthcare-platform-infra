output "postgresql_server_fqdn" {
  description = "The fully qualified domain name (FQDN) of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.db.fqdn
}

output "key_vault_id" {
  description = "The Resource ID of the Healthcare Key Vault HSM"
  value       = azurerm_key_vault.health.id
}

output "key_vault_uri" {
  description = "The URI of the Healthcare Key Vault"
  value       = azurerm_key_vault.health.vault_uri
}

output "storage_account_name" {
  description = "Name of the immutable records storage account"
  value       = azurerm_storage_account.records.name
}

output "audit_log_analytics_workspace_id" {
  description = "The ID of the HIPAA audit Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.health_audit.id
}
