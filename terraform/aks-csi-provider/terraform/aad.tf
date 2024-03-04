resource "azuread_user" "csi-provider-demo-key-vault-user" {
  user_principal_name = "${var.csi_provider_demo_key_vault_user_name}@${var.csi_provider_demo_domain_suffix}"
  display_name        = var.csi_provider_demo_key_vault_user_name
  mail_nickname       = var.csi_provider_demo_key_vault_user_name
  password            = var.csi_provider_demo_key_vault_user_password
}
