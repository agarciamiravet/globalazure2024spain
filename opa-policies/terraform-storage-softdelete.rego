package main
import input as tfplan

min_allowed_soft_delete_storage_days = 31

deny[msg] {
  r := tfplan.resource_changes[_]
  r.type == "azurerm_storage_account"
  current_soft_delete_days :=  r.change.after.blob_properties[_].container_delete_retention_policy[_].days
  total := 100
  min_allowed_soft_delete_storage_days > current_soft_delete_days
  msg := sprintf("Storage Account - Soft Delete days config is lower. Minimum is 31, and now has %v", [current_soft_delete_days])
}