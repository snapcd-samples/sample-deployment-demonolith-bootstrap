# Hands the monolith to Snap CD as a single module, so a manual job can run
# demonolith against it. The namespace is this sample's own; the stack is
# whichever one already exists.

data "snapcd_stack" "this" {
  name = var.stack_name
}

resource "snapcd_namespace" "this" {
  name           = var.namespace_name
  stack_id       = data.snapcd_stack.this.id
  default_engine = var.engine
}

data "snapcd_runner" "this" {
  name = var.runner_name
}

data "snapcd_state_store" "default" {
  name = "default"
}

# The monolith declares no backend of its own, so Snap CD supplies one: this
# file is written beside its code, and the -backend-config flags below point it
# at the state store.
resource "snapcd_namespace_extra_file" "backend" {
  file_name    = "backend.tf"
  namespace_id = snapcd_namespace.this.id
  overwrite    = false
  contents     = <<-EOT
    terraform {
      backend "http" {}
    }
  EOT
}

resource "snapcd_namespace_input_from_definition" "module_name" {
  name            = "SNAPCD_MODULE_NAME"
  namespace_id    = snapcd_namespace.this.id
  definition_name = "ModuleName"
  input_kind      = "EnvVar"
}

resource "snapcd_namespace_terraform_array_flag" "backend_config" {
  for_each = {
    address        = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_MODULE_NAME}"
    lock_address   = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_MODULE_NAME}/lock"
    unlock_address = "${var.snapcd_server_url_from_runner}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_MODULE_NAME}/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
    username       = "$${SNAPCD_CLIENT_ID}"
    password       = "$${SNAPCD_CLIENT_SECRET}"
  }

  namespace_id = snapcd_namespace.this.id
  task         = "Init"
  flag         = "BackendConfig"
  value        = "${each.key}=${each.value}"
}

resource "snapcd_module" "monolith" {
  name                = var.module_name
  namespace_id        = snapcd_namespace.this.id
  source_url          = var.source_url
  source_revision     = var.branch_name
  source_subdirectory = "module"
  runner_id           = data.snapcd_runner.this.id
  engine              = var.engine
}

# Every variable the monolith declares, as one channel. The sample's own
# scripts spread these across tfvars, the environment and a -var flag to show
# what demonolith copes with; Snap CD has one place for them, and the runner
# writes them where demonolith looks.
resource "snapcd_module_input_from_literal" "params" {
  for_each = {
    name_prefix         = var.name_prefix
    resource_group_name = var.resource_group_name
    vpc_cidr_block      = var.vpc_cidr_block
    public_subnet_cidr  = var.public_subnet_cidr
    private_subnet_cidr = var.private_subnet_cidr
    database_port       = var.database_port
  }

  module_id     = snapcd_module.monolith.id
  name          = each.key
  literal_value = each.value
  input_kind    = "Param"
  type          = "String"
}
