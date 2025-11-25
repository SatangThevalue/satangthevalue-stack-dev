pid_file = "./pidfile"

auto_auth {
  method "approle" {
    config = {
      role_id_file_path = "/vault/config/role_id"
      secret_id_file_path = "/vault/config/secret_id"
      remove_secret_id_file_after_reading = false
    }
  }
}

# Template: สร้างไฟล์ Certificate
template {
  destination = "/vault/output/server.crt"
  contents = <<EOH
{{- with secret "pki_int/issue/web-role" "common_name=*.env:DOMAIN" "ttl=24h" -}}
{{ .Data.certificate }}
{{ .Data.issuing_ca }}
{{- end -}}
EOH
}

# Template: สร้างไฟล์ Private Key
template {
  destination = "/vault/output/server.key"
  contents = <<EOH
{{- with secret "pki_int/issue/web-role" "common_name=*.env:DOMAIN" "ttl=24h" -}}
{{ .Data.private_key }}
{{- end -}}
EOH
}