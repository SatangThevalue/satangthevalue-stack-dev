# Configuration Guide

เอกสารนี้อธิบายไฟล์และตัวแปรที่ใช้ในการตั้งค่า `satangthevalue-stack-dev`

## ไฟล์ `.env`

ไฟล์นี้เป็นศูนย์กลางในการเก็บข้อมูลลับ (secrets) และการตั้งค่าต่างๆ ของโปรเจกต์ ควรสร้างไฟล์นี้โดยการคัดลอกมาจาก `.env.example`

### ตัวแปรสำคัญ:

- `COMPOSE_PROJECT_NAME`: กำหนดชื่อของโปรเจกต์ใน Docker ซึ่งจะมีผลต่อชื่อของคอนเทนเนอร์และเน็ตเวิร์ก
- `DOMAIN`: ชื่อโดเมนหลักที่ใช้ในโปรเจกต์ (ค่าเริ่มต้นคือ `localhost`)
- `POSTGRES_*`: ตัวแปรทั้งหมดที่ขึ้นต้นด้วย `POSTGRES_` ใช้สำหรับตั้งค่าฐานข้อมูล PostgreSQL ทั้งชื่อฐานข้อมูล, ผู้ใช้, และรหัสผ่าน
- `MINIO_*`: ตัวแปรสำหรับตั้งค่า MinIO Object Storage
- `VAULT_DEV_ROOT_TOKEN_ID`: Root token สำหรับเข้า Vault ใน `dev` mode
- `NEXT_PUBLIC_API_URL`: Environment variable สำหรับฝั่ง Frontend (Next.js) เพื่อให้รู้ว่าจะต้องยิง API ไปที่ URL ใด

## Traefik Configuration

การตั้งค่า Traefik แบ่งออกเป็น 2 ส่วน:

1.  **Static Configuration (`./infra/traefik/traefik.yml`):**
    ไฟล์นี้ใช้ตั้งค่าพื้นฐานของ Traefik ที่ไม่ค่อยเปลี่ยนแปลง เช่น การกำหนด Entrypoints (`web` สำหรับพอร์ต 80, `websecure` สำหรับพอร์ต 443) และการเปิดใช้งาน Docker Provider

2.  **Dynamic Configuration (Docker Labels):**
    การตั้งค่าสำหรับแต่ละเซอร์วิส (เช่น การสร้าง subdomain, การเปิดใช้งาน TLS) จะถูกกำหนดผ่าน `labels` ที่อยู่ในไฟล์ `docker-compose.yml` วิธีนี้ทำให้การเพิ่มหรือลบเซอร์วิสทำได้ง่าย โดย Traefik จะอัปเดต routing table โดยอัตโนมัติ

## Database Initialization

สคริปต์ SQL ที่อยู่ในไดเรกทอรี `./infra/postgres/initdb/` จะถูกรันโดยอัตโนมัติ **เพียงครั้งเดียว** ตอนที่คอนเทนเนอร์ PostgreSQL ถูกสร้างขึ้นครั้งแรก เหมาะสำหรับการสร้าง database schemas, roles, หรือใส่ข้อมูลเริ่มต้นที่จำเป็นสำหรับเซอร์วิสต่างๆ