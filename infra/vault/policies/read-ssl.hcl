# --- 1. Policy สำหรับ Web Server (อ่าน SSL ได้อย่างเดียว) ---
path "secret/data/prod/infra/ssl/*" {
  capabilities = ["read"]
}
# อนุญาตให้ List ดูชื่อไฟล์ได้ แต่ดูเนื้อหาไม่ได้
path "secret/metadata/prod/infra/ssl/*" {
  capabilities = ["list"]
}

# --- 2. Policy สำหรับ Backend API (อ่าน DB & Tokens) ---
# อ่านรหัส DB
path "secret/data/prod/database/credentials" {
  capabilities = ["read"]
}
# อ่าน API Tokens
path "secret/data/prod/applications/tokens/*" {
  capabilities = ["read"]
}

# --- 3. Policy สำหรับ Admin/DevOps (จัดการได้ทุกอย่างใน Prod) ---
# สังเกตว่าไม่ต้องใส่ data/ เพื่อให้ครอบคลุมทั้ง data, metadata, destroy
path "secret/prod/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
# หรือถ้าจะระบุเจาะจงให้ถูกต้องตามหลัก v2 เป๊ะๆ:
path "secret/data/prod/*" {
  capabilities = ["create", "read", "update", "delete"]
}
path "secret/metadata/prod/*" {
  capabilities = ["list", "delete"]
}
path "secret/destroy/prod/*" {
  capabilities = ["update"] # v2 ใช้ update สำหรับการ destroy version
}