# Geo-Redundant-Azure-App-Deployment-with-Terraform

Project Overview
This Terraform configuration deploys a geo-redundant Azure App Service across two regions: West US 2 (primary) and East US 2 (secondary). The deployment includes:

Resource groups, App Service Plans, App Services, and Application Insights in each region.

An Azure Traffic Manager Profile configured with Priority routing to direct traffic to the primary app by default.

Automatic failover to the secondary app if the primary becomes unavailable.

How Geo-Redundancy Works
The app (hosting the resume or any web content) is deployed in two geographically separated Azure regions for high availability.

Azure Traffic Manager monitors the health of the primary app.

If the primary app in West US 2 fails or becomes unreachable, Traffic Manager automatically routes users to the secondary app in East US 2.

This failover mechanism ensures your resume app remains accessible with minimal downtime.

Benefits
Improved reliability and availability of your web app.

Protection against regional outages or failures.

Seamless user experience with automatic routing based on app health.


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

