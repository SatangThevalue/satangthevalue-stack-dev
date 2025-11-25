#!/bin/bash

# --- การตั้งค่า (Configuration) ---
CERT_FILE="rootCA.crt"           # ชื่อไฟล์ Certificate ของคุณ
CERT_NAME="MyLocalRootCA"        # ชื่อที่จะให้แสดงใน Chrome/System
NSSDB_PATH="$HOME/.pki/nssdb"    # Path มาตรฐานของ Chrome DB บน Linux

# --- สีสำหรับข้อความ ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}--- เริ่มต้นการติดตั้ง Certificate: $CERT_FILE ---${NC}"

# 1. ตรวจสอบไฟล์
if [ ! -f "$CERT_FILE" ]; then
    echo -e "${RED}[Error] ไม่พบไฟล์ $CERT_FILE ในโฟลเดอร์ปัจจุบัน!${NC}"
    exit 1
fi

# 2. ติดตั้งระดับระบบ (System-wide)
echo -e "\n${YELLOW}[1/2] กำลังติดตั้งลงในระบบ (System-wide)...${NC}"
echo "ต้องใช้สิทธิ์ Root/Sudo ในการคัดลอกไฟล์"
sudo cp "$CERT_FILE" "/usr/local/share/ca-certificates/$CERT_NAME.crt"

if [ $? -eq 0 ]; then
    echo "กำลังอัปเดต CA Store..."
    sudo update-ca-certificates
    echo -e "${GREEN}[Success] ติดตั้งลงระบบเรียบร้อยแล้ว${NC}"
else
    echo -e "${RED}[Error] ล้มเหลวในการติดตั้งลงระบบ${NC}"
    exit 1
fi

# 3. ติดตั้งลง Chrome (NSS Database)
echo -e "\n${YELLOW}[2/2] กำลังติดตั้งลงใน Chrome Browser (NSS DB)...${NC}"

# ตรวจสอบว่ามี certutil หรือไม่
if ! command -v certutil &> /dev/null; then
    echo -e "${RED}[Error] ไม่พบคำสั่ง 'certutil'${NC}"
    echo "กรุณาติดตั้งก่อน ด้วยคำสั่ง:"
    echo "  - Debian/Ubuntu: sudo apt install libnss3-tools"
    echo "  - Fedora/RedHat: sudo dnf install nss-tools"
    exit 1
fi

# ตรวจสอบว่ามีโฟลเดอร์ DB หรือไม่ (ถ้าไม่มีก็สร้างให้)
mkdir -p "$NSSDB_PATH"

# ลบ Cert เก่าออกก่อน (ถ้ามี) เพื่อป้องกันการซ้ำซ้อนหรือไม่อัปเดต
certutil -d sql:"$NSSDB_PATH" -D -n "$CERT_NAME" 2>/dev/null

# ติดตั้ง Cert ใหม่
certutil -d sql:"$NSSDB_PATH" -A -t "C,," -n "$CERT_NAME" -i "$CERT_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[Success] ติดตั้งลง Chrome NSS DB เรียบร้อยแล้ว${NC}"
    
    # แสดงรายการเพื่อยืนยัน
    echo -e "\nตรวจสอบสถานะใน DB:"
    certutil -d sql:"$NSSDB_PATH" -L | grep "$CERT_NAME"
else
    echo -e "${RED}[Error] ล้มเหลวในการติดตั้งลง Chrome${NC}"
    exit 1
fi

echo -e "\n${GREEN}--- เสร็จสิ้นทุกขั้นตอน ---${NC}"
echo "คำแนะนำ: กรุณาปิด Chrome ให้สนิท (chrome://restart) เพื่อให้การเปลี่ยนแปลงมีผล"