# Geo-Redundant-Azure-App-Deployment-with-Terraform

This Terraform project automates the deployment of a geo-redundant Azure environment including resource groups, app service plans, web apps, application insights, and Traffic Manager for global load balancing.

Features
Creates primary and secondary Azure resource groups

Deploys App Service Plans and App Services in both locations

Configures Application Insights for monitoring

Sets up Azure Traffic Manager for global traffic distribution

Implements basic network security with NSGs (if applicable)

Prerequisites
Azure subscription with sufficient quotas

Terraform installed

Azure CLI or service principal configured for Terraform authentication

git clone https://github.com/yourusername/Geo-Redundant-Azure-App-Deployment-with-Terraform.git
cd Geo-Redundant-Azure-App-Deployment-with-Terraform


terraform init



terraform apply




Notes
This deployment requires sufficient Azure subscription quotas.

Some resource names (e.g., Traffic Manager labels) must be globally unique.

The current Terraform Azure provider version uses azurerm_app_service_plan which is deprecated, consider updating to azurerm_service_plan.

Monitor Azure portal or CLI for quota and permission issues.

