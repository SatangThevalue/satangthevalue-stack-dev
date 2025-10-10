# infra/vault/policies/nomad-server-policy.hcl

# Allow creating tokens for jobs.
path "auth/token/create" {
  capabilities = ["sudo", "update"]
}

# Allow looking up the token passed to Nomad to validate it.
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow revoking the tokens passed to Nomad.
path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

# Allow checking the token capabilities.
path "sys/capabilities-self" {
  capabilities = ["update"]
}

# Allow looking up entity info.
path "identity/entity/id/+" {
  capabilities = ["read"]
}