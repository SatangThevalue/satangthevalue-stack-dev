# infra/vault/config/vault.hcl

ui = true
disable_mlock = true
api_addr     = "https://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"
listener "tcp" {
  address       = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable   = "false"
  tls_cert_file = "/vault/certs/server.crt"
  tls_key_file  = "/vault/certs/server.key"
  tls_client_ca_file = "/vault/certs/rootCA.crt"
}
# -----------------------------------------------

storage "postgresql" {
  connection_url       = "env:VAULT_PG_CONNECTION_URL"
  table                = "vault_kv_store"
  ha_enabled           = "true"
  ha_table             = "vault_ha_locks"
  max_idle_connections = 20
  max_parallel         = "128"
}

