#!/bin/bash

# ตรวจสอบว่ามี ENV ครบไหม
if [ -z "$VAULT_ROLE_ID" ] || [ -z "$VAULT_SECRET_ID" ]; then
  echo "Error: VAULT_ROLE_ID and VAULT_SECRET_ID must be set."
  exit 1
fi

# 1. เขียน ENV ลงไฟล์ชั่วคราว (ใช้ -n เพื่อไม่ให้มี newline)
echo -n "$VAULT_ROLE_ID" > /tmp/vault-agent-role-id
echo -n "$VAULT_SECRET_ID" > /tmp/vault-agent-secret-id

# 2. ปรับสิทธิ์ไฟล์ให้ปลอดภัย (อ่านได้เฉพาะเจ้าของ)
chmod 600 /tmp/vault-agent-role-id
chmod 600 /tmp/vault-agent-secret-id

echo "Starting Vault Agent..."

# 3. รัน Vault Agent
# เมื่อ Agent เริ่มทำงาน มันจะอ่านไฟล์เหล่านี้ แล้วลบ secret-id ทิ้งตาม config
vault agent -config=agent.hcl