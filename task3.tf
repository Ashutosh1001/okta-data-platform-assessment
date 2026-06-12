terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87.0"
    }
  }
}

variable "environment_name" {
  type    = string
  default = "ANALYTICS"
}

variable "reporting_schema_name" {
  type    = string
  default = "REPORTING"
}

variable "warehouse_name" {
  type    = string
  default = "REPORTING_WH"
}

variable "rbac_role_name" {
  type    = string
  default = "REPORTING_ROLE"
}

variable "service_account_name" {
  type    = string
  default = "REPORTING_SVC_USER"
}

resource "snowflake_database" "analytics" {
  name = var.environment_name
}

resource "snowflake_schema" "reporting" {
  database = snowflake_database.analytics.name
  name     = var.reporting_schema_name
}

resource "snowflake_warehouse" "reporting_wh" {
  name                = var.warehouse_name
  warehouse_size      = "SMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
}

resource "snowflake_role" "reporting_role" {
  name = var.rbac_role_name
}

resource "snowflake_user" "reporting_svc_user" {
  name                 = var.service_account_name
  login_name           = var.service_account_name
  default_warehouse    = snowflake_warehouse.reporting_wh.name
  default_role         = snowflake_role.reporting_role.name
  must_change_password = false
  disabled             = false
}

resource "snowflake_grant_account_role" "assign_role_to_svc_user" {
  role_name = snowflake_role.reporting_role.name
  user_name = snowflake_user.reporting_svc_user.name
}

resource "snowflake_grant_privileges_to_account_role" "db_privileges" {
  privileges        = ["ALL PRIVILEGES"]
  account_role_name = snowflake_role.reporting_role.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.analytics.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "schema_privileges" {
  privileges        = ["ALL PRIVILEGES"]
  account_role_name = snowflake_role.reporting_role.name
  on_schema {
    schema_name = "\"${snowflake_database.analytics.name}\".\"${snowflake_schema.reporting.name}\""
  }
}