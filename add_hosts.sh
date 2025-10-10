#!/bin/bash

# ==============================================================================
# สคริปต์สำหรับเพิ่ม Hostnames ของโปรเจกต์ satangthevalue-stack-dev
# ไปยังไฟล์ /etc/hosts
# ต้องรันด้วยสิทธิ์ Admin (sudo)
# ==============================================================================

# --- ตรวจสอบสิทธิ์ Root/Admin ---
if [ "$(id -u)" -ne 0 ]; then
  echo "🚫 สคริปต์นี้ต้องรันด้วยสิทธิ์ root หรือใช้คำสั่ง sudo"
  echo "ตัวอย่าง: sudo ./add_hosts.sh"
  exit 1
fi

# --- ตัวแปร ---
IP_ADDRESS="127.0.0.1"
HOSTS_FILE="/etc/hosts"

# รายชื่อ Hostnames ทั้งหมดที่ใช้ในโปรเจกต์
HOSTNAMES=(
  "traefik.localhost"
  "vault.localhost"
  "consul.localhost"
  "nomad.localhost"
  "adminer.localhost"
  "minio.localhost"
  "mlflow.localhost"
  "prefect.localhost"
  "label-studio.localhost"
  "n8n.localhost"
  "jenkins.localhost"
  "api.localhost"
  "ml-api.localhost"
  "app.localhost"
  "jaeger.localhost"
)

# --- เริ่มการทำงาน ---
echo "🚀 เริ่มทำการอัปเดตไฟล์ $HOSTS_FILE..."
echo "------------------------------------------"

# วนลูปเพื่อตรวจสอบและเพิ่มแต่ละ Hostname
for host in "${HOSTNAMES[@]}"; do
  # ใช้ grep -q เพื่อค้นหาแบบเงียบๆ และ -w เพื่อให้ตรงกับคำทั้งหมด
  if ! grep -q -w "$host" "$HOSTS_FILE"; then
    echo "  ➕ กำลังเพิ่ม: $host"
    # เพิ่ม Hostname ใหม่ลงไปท้ายไฟล์
    echo "$IP_ADDRESS $host" >> "$HOSTS_FILE"
  else
    echo "  ✔️ มีอยู่แล้ว: $host (ข้าม)"
  fi
done

echo "------------------------------------------"
echo "✅ การอัปเดตไฟล์ hosts เสร็จสิ้น!"