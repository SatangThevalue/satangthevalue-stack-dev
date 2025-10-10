# satangthevalue-stack-dev

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white) ![MLflow](https://img.shields.io/badge/MLflow-0194E2?style=for-the-badge&logo=mlflow&logoColor=white) ![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

**satangthevalue-stack-dev** คือระบบจำลองสภาวะแวดล้อมเสมือนโปรดักชัน (production-parity) สำหรับการพัฒนาโปรเจกต์บนเครื่อง local แบบครบวงจร ขับเคลื่อนด้วย Docker Compose โซลูชันนี้ถูกออกแบบมาเพื่อให้นักพัฒนาสามารถเริ่มต้นโปรเจกต์ AI, MLOps และ Microservices ที่ซับซ้อนได้ทันทีด้วยคำสั่งเพียงคำสั่งเดียว


## ✨ คุณสมบัติเด่น (Features)

- **ทำงานทันที (Turnkey Solution):** `clone` โปรเจกต์และรัน `docker compose up` เพื่อเริ่มต้นระบบทั้งหมด
- **HTTPS อัตโนมัติบน Local:** ทุกเซอร์วิสทำงานภายใต้ HTTPS ที่เชื่อถือได้ในเครื่อง ผ่าน Traefik และ mkcert
- **ชุดเครื่องมือ MLOps ครบวงจร:** มาพร้อม MLflow, Prefect, และ Label Studio ที่เชื่อมต่อกันเรียบร้อย
- **Observability ในตัว:** ติดตามและตรวจสอบระบบได้ผ่าน Jaeger และ OpenTelemetry Collector
- **ฐานข้อมูลและ Storage พร้อมใช้:** มี PostgreSQL และ MinIO (S3-compatible) สำหรับจัดเก็บข้อมูลและไฟล์
- **ยืดหยุ่นและขยายได้:** ง่ายต่อการเพิ่มหรือแก้ไขเซอร์วิสให้เข้ากับความต้องการของโปรเจกต์

## 📚 เทคโนโลยีหลักใน Stack

| หมวดหมู่ | เทคโนโลยี |
| :--- | :--- |
| **Gateway & Service Mesh** | Traefik |
| **Data Persistence** | PostgreSQL, MinIO, Adminer |
| **MLOps & Automation** | MLflow, Prefect, Label Studio, Jenkins, n8n |
| **Core Platform** | Vault, Consul, Nomad (HashiCorp Stack) |
| **Observability** | Jaeger, OpenTelemetry Collector |
| **Application Services** | (Placeholder) Nest.js, FastAPI, Next.js |

---

## 🚀 เริ่มต้นใช้งาน (Getting Started)

ทำตามขั้นตอนต่อไปนี้เพื่อเปิดใช้งาน Stack ทั้งหมดบนเครื่องของคุณ

### 1. สิ่งที่ต้องมี (Prerequisites)

- **Docker & Docker Compose:** ติดตั้งเวอร์ชันล่าสุด
- **mkcert:** เครื่องมือสำหรับสร้าง Certificate ที่เชื่อถือได้ในเครื่อง ติดตั้งผ่าน [mkcert official guide](https://github.com/FiloSottile/mkcert)

### 2. สร้างใบรับรอง SSL (Certificate Setup)

ขั้นแรก ติดตั้ง Local CA ของ `mkcert` (ทำเพียงครั้งเดียวต่อเครื่อง):
```bash
mkcert -install