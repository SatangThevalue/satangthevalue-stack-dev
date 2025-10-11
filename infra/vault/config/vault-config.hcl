# infra/vault/vault-config.hcl

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}

# กำหนด Storage Backend ให้เป็น PostgreSQL โดยใช้ Credentials เฉพาะของ Vault
storage "postgresql" {
  connection_url = "postgres://${VAULT_POSTGRES_USER}:${VAULT_POSTGRES_PASSWORD}@postgres:5432/${VAULT_POSTGRES_DB}?sslmode=disable"
}

ui = true
disable_mlock = true