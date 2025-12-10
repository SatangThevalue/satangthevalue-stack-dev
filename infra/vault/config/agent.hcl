# agent.hcl

pid_file = "./pidfile"

vault {
  address = "env:VAULT_ADDR" # หรือ env:VAULT_ADDR
  # ถ้าใช้ Self-signed cert ต้องระบุ CA ด้วย
  # ca_cert = "/home/satang-the-value/local-github/satangthevalue-stack-dev/infra/traefik/certs/rootCA.crt" 
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      # ชี้ไปที่ไฟล์ชั่วคราวที่เราจะสร้างก่อนรัน
      role_id_file_path = "/tmp/vault-agent-role-id"
      secret_id_file_path = "/tmp/vault-agent-secret-id"
      
      # สำคัญ! สั่งให้ลบไฟล์ secret_id ทิ้งทันทีที่อ่านค่าเสร็จ
      remove_secret_id_file_after_reading = true
    }
  }

  # เมื่อ Login สำเร็จ ให้เขียน Token ลงไฟล์ (เพื่อให้ App อื่นมาอ่านไปใช้)
  sink "file" {
    config = {
      path = "/tmp/vault-token"
    }
  }
}

# (Optional) Template สำหรับดึง SSL หรือ Secrets อื่นๆ
template {
  destination = "./secrets/app-config.json"
  contents = <<EOH
  {
    "db_password": "{{ with secret "secret/data/prod/database" }}{{ .Data.data.password }}{{ end }}"
  }
  EOH
}