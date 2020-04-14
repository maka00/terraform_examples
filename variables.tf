variable "prefix" {
    description = "The prefix used for all resources in this example"
    default     = "dev-environment"
}

variable "location" {
    description = "The Azure location where all resources should be created"
    default     = "westeurope"
}

variable "postgresql_master_password" {
    description = "postgresql master password"
    default = ""
}

