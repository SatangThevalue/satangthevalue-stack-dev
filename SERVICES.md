# Service Reference Guide

เอกสารนี้ให้ข้อมูลโดยละเอียดเกี่ยวกับแต่ละเซอร์วิสที่ทำงานอยู่ใน `satangthevalue-stack-dev`

---

### Gateway

#### Traefik
- **Docker Image:** `traefik:v3.0`
- **หน้าที่:** Reverse Proxy และ API Gateway ทำหน้าที่รับทราฟฟิกทั้งหมด, จัดการ SSL, และส่งต่อไปยังเซอร์วิสที่ถูกต้อง
- **URL:** `https://traefik.localhost` (Dashboard)
- **ข้อมูลเข้าระบบ:** `admin` / `password`
- **หมายเหตุ:** การตั้งค่า routing ทั้งหมดถูกกำหนดผ่าน `labels` ในไฟล์ `docker-compose.yml`

---

### Data Persistence

#### PostgreSQL
- **Docker Image:** `postgres:16`
- **หน้าที่:** ฐานข้อมูลหลักแบบ Relational สำหรับจัดเก็บข้อมูลของแอปพลิเคชัน, MLflow, Prefect
- **Hostname ภายใน:** `postgres:5432`
- **ข้อมูลเข้าระบบ:** `${POSTGRES_USER}`, `${POSTGRES_PASSWORD}`
- **การเข้าถึง:** แนะนำให้ใช้ `Adminer` หรือเชื่อมต่อโดยตรงจากแอปพลิเคชัน

#### MinIO
- **Docker Image:** `minio/minio:latest`
- **หน้าที่:** S3-compatible Object Storage สำหรับจัดเก็บไฟล์ขนาดใหญ่ เช่น ML models, artifacts, datasets
- **URL:** `https://minio.localhost` (Web Console)
- **Hostname ภายใน:** `minio:9000` (API Endpoint)
- **ข้อมูลเข้าระบบ:** `${MINIO_ROOT_USER}`, `${MINIO_ROOT_PASSWORD}`

#### Adminer
- **Docker Image:** `adminer:latest`
- **หน้าที่:** Web UI สำหรับจัดการฐานข้อมูล PostgreSQL
- **URL:** `https://adminer.localhost`
- **ข้อมูลเข้าระบบ:** ใช้ข้อมูลของ PostgreSQL ในการล็อกอิน (Server: `postgres`)

---

### MLOps & Automation

#### MLflow
- **Docker Image:** `ghcr.io/mlflow/mlflow:v2.14.1`
- **หน้าที่:** แพลตฟอร์มสำหรับติดตามการทดลอง (Experiment Tracking), จัดการโมเดล (Model Registry), และ ML Lifecycle
- **URL:** `https://mlflow.localhost`
- **การเชื่อมต่อ:**
    - **Backend Store:** PostgreSQL (`postgres`)
    - **Artifact Store:** MinIO (`minio`)

#### Prefect
- **Docker Image:** `prefecthq/prefect:2-latest`
- **หน้าที่:** Workflow orchestration tool สำหรับสร้าง, จัดตารางเวลา, และติดตาม Data Pipelines
- **URL:** `https://prefect.localhost`
- **การเชื่อมต่อ:** ใช้ PostgreSQL เป็น Backend สำหรับจัดเก็บข้อมูล Flow และ Task Runs

*... (สามารถเพิ่มรายละเอียดของ Jenkins, Label Studio, n8n, และเซอร์วิสอื่นๆ ตามฟอร์แมตเดียวกัน) ...*

---

### Observability

#### Jaeger
- **Docker Image:** `jaegertracing/all-in-one:1.53`
- **หน้าที่:** ระบบ Distributed Tracing สำหรับติดตามและวิเคราะห์คำขอที่วิ่งผ่านไมโครเซอร์วิสต่างๆ
- **URL:** `https://jaeger.localhost`

#### OpenTelemetry Collector
- **Docker Image:** `otel/opentelemetry-collector-contrib:0.95.0`
- **หน้าที่:** รับข้อมูล Traces และ Metrics จากแอปพลิเคชันผ่านโปรโตคอล OTLP และส่งต่อไปยัง Jaeger
- **Hostname ภายใน:** `otel-collector`