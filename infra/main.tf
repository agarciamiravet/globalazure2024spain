resource "azurerm_resource_group" "this" {
  name     = "rg-globalazure-2022-spain"
  location = "West Europe"
}

resource "azurerm_storage_account" "this" {
  name                     = "stga2022sspain"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  blob_properties {
    container_delete_retention_policy {
      days = 32
    }
  }
}

resource "azurerm_storage_container" "datos" {
  name                  = "datos-importantes"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}


#######################################################################
######## KEY VAULT
#######################################################################
resource "azurerm_key_vault" "this" {
  name                        = "kv-gaspain2024"
  location                    = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

}


#####################################################################################
##### COSMOSDB
#####################################################################################
resource "azurerm_cosmosdb_account" "this" {
  name                = "cosmos-gaspainmad2024"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  enable_free_tier    = "true"
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    failover_priority = 0
    location          = "westeurope"
    zone_redundant    = false
  }

  tags = {
    "defaultExperience"       = "Core (SQL)"
    "hidden-cosmos-mmspecial" = ""
  }

  lifecycle {
    ignore_changes = [
      restore
    ]
  }

}

resource "azurerm_cosmosdb_sql_database" "this" {
  name                = "cosmosdb-gaspain2024"
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
}

resource "azurerm_cosmosdb_sql_container" "this" {
  name                  = "testimonios"
  resource_group_name   = azurerm_cosmosdb_account.this.resource_group_name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.this.name
  partition_key_path    = "/id"
  partition_key_version = 1
  throughput            = 400

}

#############################################################################
########### APP SERVICE PLAN
#############################################################################
resource "azurerm_service_plan" "this" {
  name                = "asp-gaspain-2024"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "this" {
  name                = "vidasinbackups"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_service_plan.this.location
  service_plan_id     = azurerm_service_plan.this.id

  https_only = true

  site_config {
    always_on = "true"
   }

     lifecycle {
    ignore_changes = [
       site_config[0].app_command_line
    ]
  }

 }

 resource "azurerm_linux_web_app" "this-api" {
  name                = "vidasinbackups-api"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_service_plan.this.location
  service_plan_id     = azurerm_service_plan.this.id

  https_only = true

  site_config {
    always_on = "true"

    cors {
      allowed_origins = ["https://vidasinbackups.azurewebsites.net"]
    }
   }


     lifecycle {
    ignore_changes = [
       site_config[0].app_command_line
    ]
  }

 }

###############################################################
######### AZURE SQL SERVER
###############################################################
resource "azurerm_sql_server" "this" {
  name                         = "sql-gaspain-2024"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  version                      = "12.0"
  administrator_login          = var.sql_server_admin_user
  administrator_login_password = var.sql_server_password_user
}

resource "azurerm_sql_database" "this" {
  name                = "sqldb-gaspain-2024"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  server_name         = azurerm_sql_server.this.name

  requested_service_objective_name = "Basic"

  # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = true
  }
}