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