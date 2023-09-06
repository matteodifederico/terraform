#region Terraform configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}
#endregion

#region Resource group
resource "azurerm_resource_group" "rg-prod" {
  name     = "rg-${var.name}-prod"
  location = var.region

  tags = {
    environment = "prod"
    businessimpact = var.businessImpact
    workload = var.name
  }
}

resource "azurerm_resource_group" "rg-dev" {
  name     = "rg-${var.name}-dev"
  location = var.region

  tags = {
    environment = "dev"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Azure SQL Server
resource "azurerm_mssql_server" "sql-server-prod" {
  name                         = "sql-${var.name}-prod"
  resource_group_name          = azurerm_resource_group.rg-prod.name
  location                     = azurerm_resource_group.rg-prod.location
  version                      = "12.0"
  administrator_login          = var.db.prod.adminName
  administrator_login_password = var.db.prod.adminPassword
  minimum_tls_version          = "1.2"

  tags = {
    environment = "prod"
    businessimpact = var.businessImpact
    workload = var.name
  }
}

resource "azurerm_mssql_server" "sql-server-dev" {
  name                         = "sql-${var.name}-prod"
  resource_group_name          = azurerm_resource_group.rg-dev.name
  location                     = azurerm_resource_group.rg-dev.location
  version                      = "12.0"
  administrator_login          = var.db.dev.adminName
  administrator_login_password = var.db.dev.adminPassword
  minimum_tls_version          = "1.2"

  tags = {
    environment = "dev"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Azure SQL Database
resource "azurerm_mssql_database" "sql-database-prod" {
  name = "db-${var.name}-prod"
  server_id  = azurerm_mssql_server.sql-server-prod.id
  sku_name = var.db.prod.sku

  tags = {
    environment = "prod"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
resource "azurerm_mssql_database" "sql-database-dev" {
  name = "db-${var.name}-dev"
  server_id = azurerm_mssql_server.sql-server-dev.id
  sku_name = var.db.dev.sku

  tags = {
    environment = "dev"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Add Application to Azure SQL Server firewall
resource "azurerm_mssql_firewall_rule" "db-firewall-rule-prod" {
  for_each = toset(var.allowIps.prod)
  name = "web app"
  server_id = azurerm_mssql_server.sql-server-prod.id
  start_ip_address = each.key
  end_ip_address = each.key
}
resource "azurerm_mssql_firewall_rule" "db-firewall-rule-dev" {
  for_each = toset(var.allowIps.prod)
  name = "web app"
  server_id = azurerm_mssql_server.sql-server-dev.id
  start_ip_address = each.key
  end_ip_address = each.key
}
#endregion