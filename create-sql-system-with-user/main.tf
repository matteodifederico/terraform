#region Terraform configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
    mssql = {
      source = "betr-io/mssql"
      version = "0.1.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

provider "mssql" {
  debug = "false"
}

data "azurerm_client_config" "current" {
}
#endregion

#region Resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.name}-${var.environment}"
  location = var.region

  tags = {
    environment = var.environment
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Azure SQL Server
resource "azurerm_mssql_server" "sql-server" {
  name                         = "sql-${var.name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db.adminName
  administrator_login_password = var.db.adminPassword
  minimum_tls_version          = "1.2"

  tags = {
    environment = var.environment
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Azure SQL Database
resource "azurerm_mssql_database" "sql-database" {
  name = "db-${var.name}-${var.environment}"
  server_id  = azurerm_mssql_server.sql-server.id
  sku_name = var.db.sku

  tags = {
    environment = var.environment
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Add Application to Azure SQL Server firewall
resource "azurerm_mssql_firewall_rule" "db-firewall-rule" {
  for_each = toset(var.allowIps.prod)
  name = "IPs whitelist"
  server_id = azurerm_mssql_server.sql-server.id
  start_ip_address = each.key
  end_ip_address = each.key
}
#endregion

#region Create Azure SQL Server user
resource "azurerm_user_assigned_identity" "identity-user" {
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  name = var.user.name
}

resource "mssql_user" "db-user" {
  server {
    host = azurerm_mssql_server.sql-server.fully_qualified_domain_name
    azure_login {
      tenant_id    = azurerm_mssql_server.sql-server.identity[0].tenant_id
      client_id    = azurerm_user_assigned_identity.identity-user.client_id
      client_secret = data.azurerm_client_config.current.client_id

    }
  }

  database = azurerm_mssql_database.sql-database.name
  username = azurerm_user_assigned_identity.identity-user.name

  roles = var.user.roles
}
#endregion