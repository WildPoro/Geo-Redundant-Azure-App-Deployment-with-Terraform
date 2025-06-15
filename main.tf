terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"  # Use the official Azure provider from HashiCorp
      version = ">= 3.80.0"           # Require version 3.80.0 or higher of azurerm
    }
  }
}

provider "azurerm" {
  features {}                      # Enable all default features for the Azure provider
  subscription_id = "eca410d1-a4cf-47e5-9060-f48a70361368"  # Azure subscription to deploy resources into
}

variable "primary_region" {
  default = "West US 2"            # Primary Azure region for deployment
}

variable "secondary_region" {
  default = "East US 2"            # Secondary Azure region for disaster recovery/failover
}

variable "app_name" {
  default = "myApp"                # Base name for resources (can be customized)
}

# Create the primary resource group in the primary region
resource "azurerm_resource_group" "primary" {
  name     = "${var.app_name}-primary-rg"  # Resource group name: e.g. myApp-primary-rg
  location = var.primary_region             # Location for the primary RG
}

# Create the secondary resource group in the secondary region
resource "azurerm_resource_group" "secondary" {
  name     = "${var.app_name}-secondary-rg" # Resource group name: e.g. myApp-secondary-rg
  location = var.secondary_region            # Location for the secondary RG
}

# Create Application Insights resource in primary RG for monitoring and diagnostics
resource "azurerm_application_insights" "primary" {
  name                = "${var.app_name}-appinsights"          # Name for primary App Insights resource
  location            = azurerm_resource_group.primary.location # Same location as primary RG
  resource_group_name = azurerm_resource_group.primary.name     # Associate with primary RG
  application_type    = "web"                                   # Set type to web app monitoring
}

# Create Application Insights resource in secondary RG for redundancy
resource "azurerm_application_insights" "secondary" {
  name                = "${var.app_name}-appinsights-secondary" # Secondary App Insights name
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  application_type    = "web"
}

# Create App Service Plan in the primary region (Linux)
resource "azurerm_app_service_plan" "primary" {
  name                = "${var.app_name}-plan-primary"          # Name for primary App Service Plan
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  kind                = "Linux"                                # Specify Linux hosting
  reserved            = true                                   # Required to run Linux plans on Azure

  sku {
    tier = "Standard"    # Pricing tier - Standard supports features like scale-out
    size = "S1"          # Size of the plan (small instance)
  }
}

# Create App Service Plan in the secondary region (Linux)
resource "azurerm_app_service_plan" "secondary" {
  name                = "${var.app_name}-plan-secondary"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Create App Service (Web App) in primary region using the primary App Service Plan
resource "azurerm_app_service" "primary" {
  name                = "${var.app_name}-primary"               # Name of the primary app service
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  app_service_plan_id = azurerm_app_service_plan.primary.id      # Link to the primary app service plan

  site_config {
    linux_fx_version = "PHP|8.0"                                # Set runtime stack (PHP 8.0 on Linux)
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.primary.instrumentation_key
    # Set Application Insights key for telemetry
  }

  depends_on = [azurerm_application_insights.primary]           # Ensure App Insights created first
}

# Create App Service (Web App) in secondary region using the secondary App Service Plan
resource "azurerm_app_service" "secondary" {
  name                = "${var.app_name}-secondary"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  app_service_plan_id = azurerm_app_service_plan.secondary.id

  site_config {
    linux_fx_version = "PHP|8.0"
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.secondary.instrumentation_key
  }

  depends_on = [azurerm_application_insights.secondary]
}

# Create a Traffic Manager profile for DNS-based traffic routing across regions
resource "azurerm_traffic_manager_profile" "global" {
  name                   = "${var.app_name}-traffic"          # Traffic Manager profile name
  resource_group_name    = azurerm_resource_group.primary.name # Use primary RG for Traffic Manager resource
  traffic_routing_method = "Priority"                          # Use priority-based routing for failover

  dns_config {
    relative_name = "${var.app_name}-tm"                       # DNS prefix for Traffic Manager profile
    ttl           = 60                                          # DNS TTL in seconds
  }

  monitor_config {
    protocol = "HTTP"                                           # Health probe protocol
    port     = 80                                              # Health probe port
    path     = "/"                                             # Path for health check requests
  }
}

# Traffic Manager endpoint for the primary app service (highest priority)
resource "azurerm_traffic_manager_azure_endpoint" "primary" {
  name                 = "primary"                             # Endpoint name
  profile_id           = azurerm_traffic_manager_profile.global.id # Link to Traffic Manager profile
  target_resource_id   = azurerm_app_service.primary.id          # Target primary app service resource
  priority             = 1                                        # Highest priority
}

# Traffic Manager endpoint for the secondary app service (failover)
resource "azurerm_traffic_manager_azure_endpoint" "secondary" {
  name                 = "secondary"
  profile_id           = azurerm_traffic_manager_profile.global.id
  target_resource_id   = azurerm_app_service.secondary.id
  priority             = 2                                        # Lower priority (failover)
}

# Output the Traffic Manager DNS name (the global production endpoint)
output "production_url" {
  value = "https://${azurerm_traffic_manager_profile.global.fqdn}"  # URL to access app via Traffic Manager
}

# Output the direct URL for the primary App Service
output "primary_url" {
  value = "https://${azurerm_app_service.primary.default_site_hostname}"
}

# Output the direct URL for the secondary App Service
output "secondary_url" {
  value = "https://${azurerm_app_service.secondary.default_site_hostname}"
}
