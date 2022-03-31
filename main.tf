terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.92.0"
    }
  }
}

provider "azurerm" {
  subscription_id = ""
  # subscription_id = ""
  # client_id       = ""
  # client_secret   = ""
  tenant_id       = ""
  features {}
}

locals {
  resource_group="app-grp1"
  location="East US"  
}

resource "azurerm_resource_group" "app_grp1"{
  name=local.resource_group
  location=local.location
}

resource "azurerm_app_service_plan" "app_plan1000" {
  name                = "app-plan1000"
  location            = azurerm_resource_group.app_grp1.location
  resource_group_name = azurerm_resource_group.app_grp1.name

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "webapp" {
  name                = "lengochieu-webappsql321" 
  location            = azurerm_resource_group.app_grp1.location
  resource_group_name = azurerm_resource_group.app_grp1.name
  app_service_plan_id = azurerm_app_service_plan.app_plan1000.id
     source_control {
    repo_url           = "https://github.com/lengochieu1604/terrraform-sql"
    branch             = "main"
    manual_integration = true
    use_mercurial      = false
  }
  depends_on=[azurerm_app_service_plan.app_plan1000]
}

resource "azurerm_sql_server" "app_server" {
  name                         = "appserver7531"
  resource_group_name          = azurerm_resource_group.app_grp1.name
  location                     = azurerm_resource_group.app_grp1.location 
  version                      = "12.0"
  administrator_login          = ""
  administrator_login_password = ""
}

resource "azurerm_sql_database" "app_db" {
  name                = "appdb"
  resource_group_name = azurerm_resource_group.app_grp1.name
  location            = azurerm_resource_group.app_grp1.location 
  server_name         = azurerm_sql_server.app_server.name
   depends_on = [
     azurerm_sql_server.app_server
   ]
}

resource "azurerm_sql_firewall_rule" "app_server_firewall_rule_Azure_services" {
  name                = "app-server-firewall-rule-Allow-Azure-services"
  resource_group_name = azurerm_resource_group.app_grp1.name
  server_name         = azurerm_sql_server.app_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
  depends_on=[
    azurerm_sql_server.app_server
  ]
}

resource "azurerm_sql_firewall_rule" "app_server_firewall_rule" {
  name                = "app-server-firewall-rule"
  resource_group_name = azurerm_resource_group.app_grp1.name
  server_name         = azurerm_sql_server.app_server.name
  start_ip_address    = ""
  end_ip_address      = ""
  depends_on=[
    azurerm_sql_server.app_server
  ]
}

resource "null_resource" "database_setup" {
  provisioner "local-exec" {
      command = "sqlcmd -S appserver7531.database.windows.net -U sqladmin -P your_pasword -d appdb -i init.sql"
  }
  depends_on=[
    azurerm_sql_server.app_server
  ]
}
