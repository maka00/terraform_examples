output "db_master_pwd" {
  value = "${azurerm_postgresql_server.main.administrator_login_password}"
}

output "app_service_default_hostname" {
  value = "https://${azurerm_app_service.main.default_site_hostname}"
}