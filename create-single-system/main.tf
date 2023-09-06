#region Variables
variable "name" {
  type = string
}
variable "region" {
  type = string
}
variable "businessImpact" {
  type = string
}
variable "operatingSystem" {
  type = string
}
variable "dotnetVersion" {
  type = string
}
variable "stack" {
  type = string
}
variable "sku" {
  type = string
  default = "B1"
}
variable "environment" {
  type = string
  default = "prod"
}
variable "db" {
  type = object({
    type = string
    sku = string
    adminName = string
    adminPassword = string
    connectionString = string
  })
}
#endregion

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
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.name}-${var.environment}"
  location = var.region

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Azure SQL Server
resource "azurerm_mssql_server" "sql-server" {
  count = var.db.connectionString == "" ? 1 : 0
  name                         = "sql-${var.name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db.adminName
  administrator_login_password = var.db.adminPassword
  minimum_tls_version          = "1.2"

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Azure SQL Database
resource "azurerm_mssql_database" "sql-database" {
  count = var.db.connectionString == "" ? 1 : 0
  name = "db-${var.name}-${var.environment}"
  server_id  = azurerm_mssql_server.sql-server ? azurerm_mssql_server.sql-server[*].id : ""
  sku_name = var.db.sku

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Server farms (app service plans)
resource "azurerm_service_plan" "plan" {
  name = "plan-${var.name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  os_type = var.operatingSystem
  sku_name = var.sku

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region App insights
resource "azurerm_application_insights" "app-insights" {
  name = "insights-${var.name}-${var.environment}-${var.region}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type = "web"
}
#endregion

#region Webapps
resource "azurerm_windows_web_app" "webapp" {
  name = "app-${var.name}-${var.environment}-${var.region}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  service_plan_id = azurerm_service_plan.plan.id
  https_only = true

  site_config {
    application_stack {
      current_stack  = try(var.stack, "dotnet")
      dotnet_version = try(var.dotnetVersion, "v6.0")
    }
  }

  connection_string {
    name = "ConnectionString"
    type = var.db.type
    value = var.db.connectionString != "" ? var.db.connectionString : "tcp:${azurerm_mssql_server.sql-server[*].name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.sql-database[*].name};Persist Security Info=False;User ID=${var.db.adminName};Password=${var.db.adminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"
  }

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.app-insights.instrumentation_key
  }

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Add Application to Azure SQL Server firewall
resource "azurerm_mssql_firewall_rule" "db-firewall-rule" {
  for_each = var.db.connectionString == "" ? toset(azurerm_windows_web_app.webapp.outbound_ip_address_list) : []
  name = "web app ${var.name}-${var.environment}"
  server_id = azurerm_mssql_server.sql-server[*].id
  start_ip_address = each.key
  end_ip_address = each.key
}
#endregion