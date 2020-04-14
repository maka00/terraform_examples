##########################################################################################
# The main terraform file 
# Sets up a PostgreSQL server and one Application Server
# The application server is configured (SpringBoot) to link to the DB
# The DB password is asked on startup, if none is given a random pwd will be created
##########################################################################################

provider "azurerm" {
    features {}
    version = "=2.2"
    subscription_id = "your-subscription-id"
}

provider "random" {
    version = "= 2.2"
}

terraform {
    backend "azurerm" {
        resource_group_name   = "cloud-shell-storage-westeurope"
        storage_account_name  = "your-terraform-storage-account-name"
        container_name        = "your-container-name"
        key                   = "devel.tfstate"
    }
}
resource "azurerm_resource_group" "main" {
    name     = "${var.prefix}-resources"
    location = "${var.location}"
}

resource "random_password" "password" {
    length = 16
    special = true
    override_special = "_%@"
}

resource "azurerm_postgresql_server" "main" {
    name                = "${var.prefix}-postgresql-server"
    location            = "${azurerm_resource_group.main.location}"
    resource_group_name = "${azurerm_resource_group.main.name}"

    sku_name = "B_Gen5_2"

    storage_profile {
        storage_mb            = 5120
        backup_retention_days = 7
        geo_redundant_backup  = "Disabled"
    }

    administrator_login          = "dbmaster"
    administrator_login_password = "${var.postgresql_master_password}" != "" ? "${var.postgresql_master_password}" : "${random_password.password.result}"
    version                      = "10.0"
    ssl_enforcement              = "Enabled"
}

resource "azurerm_postgresql_database" "main" {
    name                = "horreumdb"
    resource_group_name = "${azurerm_resource_group.main.name}"
    server_name         = "${azurerm_postgresql_server.main.name}"
    charset             = "UTF8"
    collation           = "English_United States.1252"
}

# This rule is to enable the 'Allow access to Azure services' checkbox
resource "azurerm_postgresql_firewall_rule" "main_azure" {
    name                = "${var.prefix}-postgresql-firewall-azure"
    resource_group_name = "${azurerm_resource_group.main.name}"
    server_name         = "${azurerm_postgresql_server.main.name}"
    start_ip_address    = "0.0.0.0"
    end_ip_address      = "0.0.0.0"
}

resource "azurerm_postgresql_firewall_rule" "main" {
    name                = "${var.prefix}-postgresql-firewall-external"
    resource_group_name = "${azurerm_resource_group.main.name}"
    server_name         = "${azurerm_postgresql_server.main.name}"
    start_ip_address    = "0.0.0.0"
    end_ip_address      = "255.255.255.255"
}

## configure the app service
# A F1 instance does not support terraform!
resource "azurerm_app_service_plan" "main" {
    name                = "${var.prefix}-asp"
    location            = "${azurerm_resource_group.main.location}"
    resource_group_name = "${azurerm_resource_group.main.name}"
    kind                = "Linux"
    reserved            = true

    sku {
        tier = "Basic"
        size = "B1"
    }
}

resource "azurerm_app_service" "main" {
    name                = "${var.prefix}-appservice"
    location            = "${azurerm_resource_group.main.location}"
    resource_group_name = "${azurerm_resource_group.main.name}"
    app_service_plan_id = "${azurerm_app_service_plan.main.id}"

    site_config {
        java_version    = "11"
        java_container  = "JAVA"
    }

    app_settings = {
        "SPRING_DATASOURCE_USERNAME" = "${azurerm_postgresql_server.main.administrator_login}@${azurerm_postgresql_server.main.name}"
        "SPRING_DATASOURCE_PASSWORD" = "${azurerm_postgresql_server.main.administrator_login_password}"
        "SPRING_DATASOURCE_URL" = "jdbc:postgresql://${azurerm_postgresql_server.main.fqdn}:5432/${azurerm_postgresql_database.main.name}?sslmode=require" 
    }

}
