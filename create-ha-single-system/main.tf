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

#region Storage Account
resource "azurerm_storage_account" "storage" {
  name = lower("storage${var.name}${var.environment}")
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = var.storage.tier
  account_replication_type = var.storage.replication
  account_kind = var.storage.kind

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Azure SQL Server
resource "azurerm_mssql_server" "sql-server-primary" {
  name = lower("sql-${var.name}-${var.environment}")
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  version = "12.0"
  administrator_login = var.db.adminName
  administrator_login_password = var.db.adminPassword
  minimum_tls_version = "1.2"

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}

resource "azurerm_mssql_server" "sql-server-secondary" {
  name = lower("sql-${var.name}-${var.environment}")
  resource_group_name = azurerm_resource_group.rg.name
  location = var.failoverRegion
  version = "12.0"
  administrator_login = var.db.adminName
  administrator_login_password = var.db.adminPassword
  minimum_tls_version = "1.2"

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Azure SQL Database
resource "azurerm_mssql_database" "sql-database" {
  name = "db-${var.name}-${var.environment}"
  server_id  = tostring(azurerm_mssql_server.sql-server-primary.id)
  sku_name = var.db.sku

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Azure SQL Failover Group
resource "azurerm_mssql_failover_group" "failover-group" {
  name = lower("failover-${var.name}-${var.environment}")
  server_id = azurerm_mssql_server.sql-server-primary.id
  databases = [
    azurerm_mssql_database.sql-database.id
  ]

  partner_server {
    id = azurerm_mssql_server.sql-server-secondary.id
  }

  read_write_endpoint_failover_policy {
    mode = "Automatic"
    grace_minutes = 60
  }

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
    value = "tcp:${tostring(azurerm_mssql_failover_group.failover-group.name)}.database.windows.net;Initial Catalog=${tostring(azurerm_mssql_database.sql-database.name)};Persist Security Info=False;User ID=${var.db.adminName};Password=${var.db.adminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"
  }

  app_settings = {
    STORAGEACCOUNT_CONNECTIONSTRING = azurerm_storage_account.storage.primary_connection_string
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
/* resource "azurerm_mssql_firewall_rule" "db-primary-firewall-rule" {
  for_each = toset(azurerm_windows_web_app.webapp.outbound_ip_address_list) : []
  name = "web app ${var.name}-${var.environment}"
  server_id = azurerm_mssql_server.sql-server-primary.id
  start_ip_address = each.key
  end_ip_address = each.key
} */
/* resource "azurerm_mssql_firewall_rule" "db-secondary-firewall-rule" {
  for_each = toset(azurerm_windows_web_app.webapp.outbound_ip_address_list) : []
  name = "web app ${var.name}-${var.environment}"
  server_id = azurerm_mssql_server.sql-server-secondary.id
  start_ip_address = each.key
  end_ip_address = each.key
} */
#endregion

#region Deloyment slots
resource "azurerm_windows_web_app_slot" "slot" {
  name = "staging"
  app_service_id = azurerm_windows_web_app.webapp.id
  
  site_config {
    application_stack {
      current_stack  = try(var.stack, "dotnet")
      dotnet_version = try(var.dotnetVersion, "v6.0")
    }
  }

  connection_string {
    name = "ConnectionString"
    type = var.db.type
    value = "tcp:${tostring(azurerm_mssql_failover_group.failover-group.name)}.database.windows.net;Initial Catalog=${tostring(azurerm_mssql_database.sql-database.name)};Persist Security Info=False;User ID=${var.db.adminName};Password=${var.db.adminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"
  }

  app_settings = {
    STORAGEACCOUNT_CONNECTIONSTRING = azurerm_storage_account.storage.primary_connection_string
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.app-insights.instrumentation_key
  }

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region Azure Front Door
resource "azurerm_frontdoor" "frontdoor" {
  name = "frontdoor-${var.name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name

  frontend_endpoint {
    name = "${var.name}"
    host_name = "${var.name}.azurefd.net"
  }

  backend_pool_load_balancing {
    name = "lb-default"
    sample_size = 4
    successful_samples_required = 2
  }

  backend_pool_health_probe {
    name = "healt-probe-default"
    path = "/"
    protocol = "Http"
    interval_in_seconds = 30
  }

  backend_pool {
    name = "origin-group-default"
    load_balancing_name = "lb-default"
    health_probe_name = "healt-probe-default"
    backend {
      host_header = azurerm_windows_web_app.webapp.default_hostname
      address = azurerm_windows_web_app.webapp.default_hostname
      http_port = 80
      https_port = 443
      priority = 1
      weight = 1000
    }
  }

  routing_rule {
    frontend_endpoints = ["${var.name}"]
    name = "route-default"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match = ["/*", "/"]
    forwarding_configuration {
      backend_pool_name = "origin-group-default"
    }
  }

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion