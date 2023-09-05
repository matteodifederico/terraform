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
variable "db" {
  type = object({
    prod = object({
      type = string
      sku = string
      adminName = string
      adminPassword = string
      connectionString = string
    })
    dev = object({
      type = string
      sku = string
      adminName = string
      adminPassword = string
      connectionString = string
    })
  })
}
variable "sku" {
  type = object({
    prod = string
    dev = string
  })
  default = {
    prod = "S1"
    dev = "B1"
  }
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
  count = var.db.prod.connectionString == "" ? 1 : 0
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
  count = var.db.dev.connectionString == "" ? 1 : 0
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
  count = var.db.prod.connectionString == "" ? 1 : 0
  name = "db-${var.name}-prod"
  server_id  = azurerm_mssql_server.sql-server-prod ? azurerm_mssql_server.sql-server-prod[*].id : ""
  sku_name = var.db.prod.sku

  tags = {
    environment = "prod"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
resource "azurerm_mssql_database" "sql-database-dev" {
  count = var.db.dev.connectionString == "" ? 1 : 0
  name = "db-${var.name}-dev"
  server_id = azurerm_mssql_server.sql-server-dev ? azurerm_mssql_server.sql-server-dev[*].id : ""
  sku_name = var.db.dev.sku

  tags = {
    environment = "dev"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Server farms (app service plans)
resource "azurerm_service_plan" "plan-prod" {
  name = "plan-${var.name}-prod"
  resource_group_name = azurerm_resource_group.rg-prod.name
  location = azurerm_resource_group.rg-prod.location
  os_type = var.operatingSystem
  sku_name = var.sku.prod

  tags = {
    environment = "prod"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
resource "azurerm_service_plan" "plan-dev" {
  name = "plan-${var.name}-dev"
  resource_group_name = azurerm_resource_group.rg-dev.name
  location = azurerm_resource_group.rg-dev.location
  os_type = var.operatingSystem
  sku_name = var.sku.dev

  tags = {
    environment = "dev"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region App insights
resource "azurerm_application_insights" "app-insights-prod" {
  name = "insights-${var.name}-prod-${var.region}"
  location = azurerm_resource_group.rg-prod.location
  resource_group_name = azurerm_resource_group.rg-prod.name
  application_type = "web"
}
resource "azurerm_application_insights" "app-insights-dev" {
  name = "insights-${var.name}-dev-${var.region}"
  location = azurerm_resource_group.rg-dev.location
  resource_group_name = azurerm_resource_group.rg-dev.name
  application_type = "web"
}
#endregion

#region Webapps
resource "azurerm_windows_web_app" "webapp-prod" {
  name = "app-${var.name}-prod-${var.region}"
  resource_group_name = azurerm_resource_group.rg-prod.name
  location = azurerm_resource_group.rg-prod.location
  service_plan_id = azurerm_service_plan.plan-prod.id
  https_only = true

  site_config {
    application_stack {
      current_stack  = try(var.stack, "dotnet")
      dotnet_version = try(var.dotnetVersion, "v6.0")
    }
  }

  connection_string {
    name = "ConnectionString"
    type = var.db.prod.type
    value = var.db.prod.connectionString != "" ? var.db.prod.connectionString : "tcp:${azurerm_mssql_server.sql-server-prod[*].name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.sql-database-prod[*].name};Persist Security Info=False;User ID=${var.db.prod.adminName};Password=${var.db.prod.adminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"
  }

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.app-insights-prod.instrumentation_key
  }

  tags = {
    environment = "prod"
    businessimpact = var.businessImpact
    workload = var.name
  }
}

resource "azurerm_windows_web_app" "webapp-dev" {
  name = "app-${var.name}-dev-${var.region}"
  resource_group_name = azurerm_resource_group.rg-dev.name
  location = azurerm_resource_group.rg-dev.location
  service_plan_id = azurerm_service_plan.plan-dev.id
  https_only = true

  site_config {
    application_stack {
      current_stack  = try(var.stack, "dotnet")
      dotnet_version = try(var.dotnetVersion, "v6.0")
    }
  }

  connection_string {
    name = "ConnectionString"
    type = var.db.dev.type
    value = var.db.dev.connectionString != "" ? var.db.dev.connectionString : "tcp:${azurerm_mssql_server.sql-server-dev[*].name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.sql-database-dev[*].name};Persist Security Info=False;User ID=${var.db.dev.adminName};Password=${var.db.dev.adminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"
  }

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.app-insights-dev.instrumentation_key
  }

  tags = {
    environment = "dev"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Add Application to Azure SQL Server firewall
resource "azurerm_mssql_firewall_rule" "db-firewall-rule-prod" {
  for_each = var.db.prod.connectionString == "" ? toset(azurerm_windows_web_app.webapp-prod.outbound_ip_address_list) : []
  name = "web app ${var.name}-prod"
  server_id = azurerm_mssql_server.sql-server-prod[*].id
  start_ip_address = each.key
  end_ip_address = each.key
}
resource "azurerm_mssql_firewall_rule" "db-firewall-rule-dev" {
  for_each = var.db.dev.connectionString == "" ? toset(azurerm_windows_web_app.webapp-dev.outbound_ip_address_list) : []
  name = "web app ${var.name}-dev"
  server_id = azurerm_mssql_server.sql-server-dev[*].id
  start_ip_address = each.key
  end_ip_address = each.key
}
#endregion