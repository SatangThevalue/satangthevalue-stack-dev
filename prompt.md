แน่นอนครับ นี่คือคำแปลทั้งหมดเป็นภาษาไทย

โซลูชันนี้เป็นระบบที่พร้อมใช้งานทันที (turnkey) ช่วยให้นักพัฒนาทุกคนสามารถเปิดใช้งานแพลตฟอร์มทั้งหมดได้ด้วยคำสั่งเดียว พร้อมการค้นหาเซอร์วิสอัตโนมัติ (service discovery) และ HTTPS ที่เชื่อถือได้ในเครื่อง (locally-trusted) สำหรับทุกเซอร์วิส

-----

## 1\. แผนภาพสถาปัตยกรรมระบบ (System Architecture Diagram)

แผนภาพนี้แสดงถึงทราฟฟิกการร้องขอ (request flow) และการทำงานร่วมกันของเซอร์วิสต่างๆ ภายในสภาพแวดล้อมสำหรับพัฒนาระบบ Project OmniSight บนเครื่อง local ทราฟฟิกทั้งหมดจะถูกส่งผ่าน **Traefik Ingress Gateway** ซึ่งทำหน้าที่ยุติการเชื่อมต่อ TLS (TLS termination) ก่อนที่จะส่งต่อไปยังเซอร์วิสที่เหมาะสม เซอร์วิสที่ทำงานอยู่เบื้องหลัง (backend) จะสื่อสารกันโดยตรงผ่านเน็ตเวิร์ก `omnisight-net` สำหรับงานต่างๆ เช่น การจัดเก็บ ML artifacts หรือข้อมูล metadata ของการทดลอง

```mermaid
graph TD
    subgraph "เครื่องของนักพัฒนา (localhost)"
        direction LR
        User -- "https://*.localhost" --> Traefik;
    end

    subgraph "Docker Network: omnisight-net"
        direction TB

        Traefik -- "HTTPS" --> App_NextJS["app.localhost (Next.js)"];
        Traefik -- "HTTPS" --> API_NestJS["api.localhost (Nest.js)"];
        Traefik -- "HTTPS" --> API_FastAPI["ml-api.localhost (FastAPI)"];
        Traefik -- "HTTPS" --> MLflow["mlflow.localhost"];
        Traefik -- "HTTPS" --> Prefect["prefect.localhost"];
        Traefik -- "HTTPS" --> LabelStudio["label-studio.localhost"];
        Traefik -- "HTTPS" --> MinIO_UI["minio.localhost (UI)"];
        Traefik -- "HTTPS" --> Adminer["adminer.localhost"];
        Traefik -- "HTTPS" --> Jenkins["jenkins.localhost"];
        Traefik -- "HTTPS" --> Jaeger["jaeger.localhost"];
        Traefik -- "HTTPS" --> Vault["vault.localhost"];
        Traefik -- "HTTPS" --> Consul["consul.localhost"];
        Traefik -- "HTTPS" --> Nomad["nomad.localhost"];
        Traefik -- "HTTPS" --> TraefikDashboard["traefik.localhost (Dashboard)"];

        subgraph "ส่วนของแอปพลิเคชัน (Application Stack)"
            App_NextJS -- "เรียก API" --> API_NestJS;
            API_NestJS -- "เรียก ML API" --> API_FastAPI;
        end

        subgraph "ส่วน MLOps และ Automation"
            MLflow -- "Metadata" --> Postgres;
            MLflow -- "Artifacts (S3)" --> MinIO_API["MinIO (API:9000)"];
            Prefect -- "ข้อมูล Backend" --> Postgres;
            LabelStudio -- "ข้อมูลและ Annotation (S3)" --> MinIO_API;
            Jenkins -- "ควบคุม Docker" --> DockerSocket["/var/run/docker.sock"];
        end

        subgraph "ส่วนจัดเก็บข้อมูล (Data Persistence)"
            Postgres[("PostgreSQL")];
            MinIO_API[("MinIO Storage")];
        end

        subgraph "ส่วนตรวจสอบและสังเกตการณ์ (Observability)"
            API_FastAPI -- "Traces (OTLP)" --> OTEL_Collector["OpenTelemetry Collector"];
            API_NestJS -- "Traces (OTLP)" --> OTEL_Collector;
            OTEL_Collector -- "ส่งออก Traces" --> Jaeger;
        end

        subgraph "เซอร์วิสหลักของแพลตฟอร์ม (Platform Services)"
            Vault;
            Consul;
            Nomad;
        end

        API_FastAPI -- "เรียกข้อมูลจาก DB" --> Postgres;
        API_FastAPI -- "โหลดโมเดล (S3)" --> MinIO_API;
        API_FastAPI -- "ดึงข้อมูลลับ" --> Vault;

    end
```

-----

## 2\. โครงสร้างไดเรกทอรีของโปรเจกต์ (Project Directory Structure)

โครงสร้างนี้จัดระเบียบไฟล์คอนฟิก, ข้อมูล และโค้ดแอปพลิเคชันทั้งหมดอย่างเป็นระบบ โดยไดเรกทอรี `infra` มีความสำคัญอย่างยิ่ง เนื่องจากบรรจุไฟล์คอนฟิกที่จำเป็นในการเริ่มต้นระบบทั้งหมด (ยกเว้นส่วนของแอปพลิเคชัน)

```plaintext
.
├── .env.example
├── docker-compose.yml
└── infra/
    ├── opentelemetry/
    │   └── otel-collector-config.yml
    ├── postgres/
    │   └── initdb/
    │       └── 01-init.sql
    └── traefik/
        ├── certs/
        │   ├── local-ca.pem
        │   └── local-cert.pem
        └── traefik.yml
```

-----

## 3\. ไฟล์คอนฟิกูเรชัน (Configuration Files)

ไฟล์เหล่านี้คือหัวใจหลักของแพลตฟอร์ม ที่กำหนดวิธีการทำงานและการเชื่อมต่อของเซอร์วิสต่างๆ

### `.env.example`

ไฟล์นี้ทำหน้าที่เป็นเทมเพลตสำหรับข้อมูลลับ (secrets) และการตั้งค่าเฉพาะสำหรับแต่ละสภาพแวดล้อม **นักพัฒนาควรคัดลอกไฟล์นี้ไปเป็น `.env` และกรอกข้อมูลให้ครบถ้วนก่อนเปิดใช้งานแพลตฟอร์ม**

```env
# ==============================================================================
# PROJECT OMNISIGHT: การตั้งค่าสำหรับสภาพแวดล้อมการพัฒนาบนเครื่อง Local
# ==============================================================================

# -- การตั้งค่าทั่วไป
COMPOSE_PROJECT_NAME=omnisight
DOMAIN=localhost

# -- ข้อมูลการเข้าถึงฐานข้อมูล PostgreSQL
# ใช้โดย PostgreSQL, MLflow, Prefect, และเซอร์วิสของแอปพลิเคชัน
POSTGRES_DB=omnisight_db
POSTGRES_USER=omniuser
POSTGRES_PASSWORD=omnipassword
POSTGRES_PORT=5432

# -- ข้อมูลการเข้าถึง S3 Storage ของ MinIO
# ใช้โดย MinIO, MLflow, และ Label Studio
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_DEFAULT_BUCKETS=omnisight-data
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001

# -- การตั้งค่า HashiCorp Vault
# Root token สำหรับการเข้าถึงบนเครื่อง local
VAULT_DEV_ROOT_TOKEN_ID=root

# -- การตั้งค่า Jenkins
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=password

# -- การตั้งค่าแอปพลิเคชัน
# URL สำหรับให้ Frontend เชื่อมต่อไปยัง API ของ Backend
NEXT_PUBLIC_API_URL=https://api.localhost

# -- การตั้งค่า Observability
# ชื่อเซอร์วิสสำหรับ Tracing
OTEL_SERVICE_NAME=omnisight-platform
```

### `infra/traefik/traefik.yml`

ไฟล์คอนฟิกแบบ static นี้ใช้สำหรับเริ่มต้นการทำงานของ Traefik, ตั้งค่า entry points, เปิดใช้งาน Docker provider, และกำหนด middleware ที่สำคัญสำหรับการ redirect จาก HTTP ไปยัง HTTPS

```yaml
# infra/traefik/traefik.yml
global:
  checkNewVersion: true
  sendAnonymousUsage: false

# ตั้งค่าการเข้าถึง API และ dashboard (แบบปลอดภัย)
api:
  dashboard: true
  insecure: false # Dashboard จะถูกเปิดเผยผ่าน router rule ที่ปลอดภัยใน docker-compose

# กำหนด entry points สำหรับทราฟฟิกเว็บ (HTTP และ HTTPS)
entryPoints:
  web:
    address: ":80"
    # กำหนด middleware สำหรับ redirect เพื่อใช้กับทราฟฟิกทั้งหมดบน entry point นี้
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"

# เปิดใช้งาน Docker เป็น configuration provider
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false # ต้องเปิดใช้งานเซอร์วิสอย่างชัดเจนผ่าน labels
    network: omnisight-net # ใช้เน็ตเวิร์กกลางของเรา

# ตั้งค่าการบันทึก log
log:
  level: INFO
```

### `infra/opentelemetry/otel-collector-config.yml`

ไฟล์นี้ใช้ตั้งค่า OpenTelemetry Collector เพื่อรับข้อมูล trace ผ่านโปรโตคอล OTLP และส่งออกไปยัง Jaeger backend โดยตรงเพื่อการแสดงผล

```yaml
# infra/opentelemetry/otel-collector-config.yml
receivers:
  otlp:
    protocols:
      grpc:
      http:

exporters:
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true

processors:
  batch:

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [jaeger]
```

### `infra/postgres/initdb/01-init.sql`

สคริปต์ตัวอย่างสำหรับการเริ่มต้น PostgreSQL สามารถเพิ่มเติมเพื่อสร้าง schemas, roles, หรือข้อมูลเริ่มต้นสำหรับไมโครเซอร์วิสต่างๆ ได้

```sql
-- infra/postgres/initdb/01-init.sql
-- สคริปต์นี้จะทำงานอัตโนมัติเมื่อคอนเทนเนอร์ PostgreSQL ถูกสร้างขึ้นครั้งแรก

-- สร้าง schemas สำหรับเซอร์วิสต่างๆ เพื่อจัดระเบียบข้อมูล
CREATE SCHEMA IF NOT EXISTS mlflow_store;
CREATE SCHEMA IF NOT EXISTS prefect_store;
CREATE SCHEMA IF NOT EXISTS app_data;

-- ตัวอย่างการสร้าง role เฉพาะสำหรับเซอร์วิส
-- CREATE ROLE my_app_user WITH LOGIN PASSWORD 'secure_password';
-- GRANT ALL PRIVILEGES ON SCHEMA app_data TO my_app_user;

SELECT 'OmniSight database initialized successfully' as status;
```

-----

## 4\. ไฟล์ `docker-compose.yml`

ไฟล์นี้เป็นตัวควบคุมระบบนิเวศของ OmniSight ทั้งหมด โดยกำหนดทุกเซอร์วิส, volume และเน็ตเวิร์ก ใช้ labels ของ Traefik สำหรับการกำหนดเส้นทาง (routing) และใช้ `depends_on` ร่วมกับ `healthcheck` เพื่อให้การเริ่มต้นระบบเป็นไปตามลำดับที่ถูกต้อง

*หมายเหตุ: Image tags ถูกกำหนดเป็นเวอร์ชันล่าสุดหรือเวอร์ชันที่เสถียร เพื่อให้สอดคล้องกับคำขอ "latest stable versions" ณ วันที่ 10 ตุลาคม 2025*

```yaml
# docker-compose.yml
version: '3.9'

services:
  # ============================================================================
  # 1. GATEWAY และ SERVICE MESH
  # ============================================================================
  traefik:
    image: traefik:v3.0
    container_name: omnisight-traefik-gateway
    command:
      - "--configfile=/etc/traefik/traefik.yml"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./infra/traefik/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./infra/traefik/certs:/etc/traefik/certs:ro
    networks:
      - omnisight-net
    labels:
      # เปิดใช้งานให้ Traefik จัดการตัวเอง
      - "traefik.enable=true"
      # Dashboard Router (แบบปลอดภัย)
      - "traefik.http.routers.traefik-dashboard.rule=Host(`traefik.${DOMAIN}`)"
      - "traefik.http.routers.traefik-dashboard.entrypoints=websecure"
      - "traefik.http.routers.traefik-dashboard.service=api@internal"
      - "traefik.http.routers.traefik-dashboard.tls=true"
      # Middleware สำหรับ basic auth ของ dashboard (ควรเปลี่ยนเป็นระบบยืนยันตัวตนจริงใน production)
      - "traefik.http.routers.traefik-dashboard.middlewares=auth"
      - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$q8eZFHjF$$Fj9UfkVvG83I0oPS59PGr." # user: admin, pass: password

  # ============================================================================
  # 2. แพลตฟอร์มหลักและ SECRETS (HASHICORP STACK)
  # ============================================================================
  vault:
    image: hashicorp/vault:1.17
    container_name: omnisight-vault
    ports:
      - "8200:8200" # เปิดเพื่อให้เข้าถึงผ่าน CLI โดยตรงได้หากต้องการ
    environment:
      - VAULT_DEV_ROOT_TOKEN_ID=${VAULT_DEV_ROOT_TOKEN_ID}
      - VAULT_ADDR=http://127.0.0.1:8200
    cap_add:
      - IPC_LOCK
    networks:
      - omnisight-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.vault.rule=Host(`vault.${DOMAIN}`)"
      - "traefik.http.routers.vault.entrypoints=websecure"
      - "traefik.http.routers.vault.tls=true"
      - "traefik.http.services.vault.loadbalancer.server.port=8200"

  consul:
    image: hashicorp/consul:1.19
    container_name: omnisight-consul
    command: "agent -dev -client=0.0.0.0 -ui"
    networks:
      - omnisight-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.consul.rule=Host(`consul.${DOMAIN}`)"
      - "traefik.http.routers.consul.entrypoints=websecure"
      - "traefik.http.routers.consul.tls=true"
      - "traefik.http.services.consul.loadbalancer.server.port=8500"

  nomad:
    image: hashicorp/nomad:1.8
    container_name: omnisight-nomad
    command: "agent -dev -bind 0.0.0.0"
    networks:
      - omnisight-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nomad.rule=Host(`nomad.${DOMAIN}`)"
      - "traefik.http.routers.nomad.entrypoints=websecure"
      - "traefik.http.routers.nomad.tls=true"
      - "traefik.http.services.nomad.loadbalancer.server.port=4646"

  # ============================================================================
  # 3. ส่วนจัดเก็บข้อมูล (DATA PERSISTENCE LAYER)
  # ============================================================================
  postgres:
    image: postgres:16
    container_name: omnisight-postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./infra/postgres/initdb:/docker-entrypoint-initdb.d
    networks:
      - omnisight-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  adminer:
    image: adminer:latest
    container_name: omnisight-adminer
    environment:
      ADMINER_DEFAULT_SERVER: postgres
    networks:
      - omnisight-net
    depends_on:
      postgres:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.adminer.rule=Host(`adminer.${DOMAIN}`)"
      - "traefik.http.routers.adminer.entrypoints=websecure"
      - "traefik.http.routers.adminer.tls=true"
      - "traefik.http.services.adminer.loadbalancer.server.port=8080"

  minio:
    image: minio/minio:latest
    container_name: omnisight-minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
      MINIO_DEFAULT_BUCKETS: ${MINIO_DEFAULT_BUCKETS}
    volumes:
      - minio-data:/data
    networks:
      - omnisight-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 10s
      timeout: 5s
      retries: 5
    labels:
      - "traefik.enable=true"
      # Router สำหรับ Web UI Console
      - "traefik.http.routers.minio-console.rule=Host(`minio.${DOMAIN}`)"
      - "traefik.http.routers.minio-console.entrypoints=websecure"
      - "traefik.http.routers.minio-console.tls=true"
      - "traefik.http.services.minio-console.loadbalancer.server.port=9001"

  # ============================================================================
  # 4. ส่วน MLOPS และ AUTOMATION
  # ============================================================================
  mlflow:
    image: ghcr.io/mlflow/mlflow:v2.14.1
    container_name: omnisight-mlflow
    command: >
      mlflow server
      --host 0.0.0.0
      --port 5000
      --backend-store-uri postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:${POSTGRES_PORT}/${POSTGRES_DB}
      --default-artifact-root s3://${MINIO_DEFAULT_BUCKETS}/mlflow/
    environment:
      - MLFLOW_S3_ENDPOINT_URL=http://minio:${MINIO_PORT}
      - AWS_ACCESS_KEY_ID=${MINIO_ROOT_USER}
      - AWS_SECRET_ACCESS_KEY=${MINIO_ROOT_PASSWORD}
    networks:
      - omnisight-net
    depends_on:
      postgres:
        condition: service_healthy
      minio:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.mlflow.rule=Host(`mlflow.${DOMAIN}`)"
      - "traefik.http.routers.mlflow.entrypoints=websecure"
      - "traefik.http.routers.mlflow.tls=true"
      - "traefik.http.services.mlflow.loadbalancer.server.port=5000"

  prefect:
    image: prefecthq/prefect:2-latest
    container_name: omnisight-prefect
    command: prefect server start
    environment:
      - PREFECT_UI_URL=https://prefect.${DOMAIN}
      - PREFECT_API_URL=https://prefect.${DOMAIN}/api
      - PREFECT_API_DATABASE_CONNECTION_URL=postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
    networks:
      - omnisight-net
    depends_on:
      postgres:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.prefect.rule=Host(`prefect.${DOMAIN}`)"
      - "traefik.http.routers.prefect.entrypoints=websecure"
      - "traefik.http.routers.prefect.tls=true"
      - "traefik.http.services.prefect.loadbalancer.server.port=4200"

  label-studio:
    image: heartexlabs/label-studio:latest
    container_name: omnisight-label-studio
    environment:
      - LABEL_STUDIO_HOST=https://label-studio.${DOMAIN}
      - MINIO_ENDPOINT=http://minio:9000
      - AWS_ACCESS_KEY_ID=${MINIO_ROOT_USER}
      - AWS_SECRET_ACCESS_KEY=${MINIO_ROOT_PASSWORD}
    volumes:
      - label-studio-data:/label-studio/data
    networks:
      - omnisight-net
    depends_on:
      - minio
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.label-studio.rule=Host(`label-studio.${DOMAIN}`)"
      - "traefik.http.routers.label-studio.entrypoints=websecure"
      - "traefik.http.routers.label-studio.tls=true"
      - "traefik.http.services.label-studio.loadbalancer.server.port=8080"
  
  n8n:
    image: n8nio/n8n:latest
    container_name: omnisight-n8n
    environment:
      - N8N_HOST=n8n.${DOMAIN}
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://n8n.${DOMAIN}/
    volumes:
      - n8n-data:/home/node/.n8n
    networks:
      - omnisight-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(`n8n.${DOMAIN}`)"
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.routers.n8n.tls=true"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"

  jenkins:
    image: jenkins/jenkins:lts-jdk17
    container_name: omnisight-jenkins
    environment:
      - JENKINS_USER=${JENKINS_ADMIN_USER}
      - JENKINS_PASS=${JENKINS_ADMIN_PASSWORD}
    volumes:
      - jenkins-data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock # Mount Docker socket เพื่อให้ Jenkins สั่งงาน Docker ได้
    networks:
      - omnisight-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.jenkins.rule=Host(`jenkins.${DOMAIN}`)"
      - "traefik.http.routers.jenkins.entrypoints=websecure"
      - "traefik.http.routers.jenkins.tls=true"
      - "traefik.http.services.jenkins.loadbalancer.server.port=8080"

  # ============================================================================
  # 5. เซอร์วิสของแอปพลิเคชัน (ตัวอย่าง)
  # ============================================================================
  api-gateway:
    image: nginxdemos/hello:plain-text
    container_name: omnisight-api-gateway
    networks:
      - omnisight-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api-gateway.rule=Host(`api.${DOMAIN}`)"
      - "traefik.http.routers.api-gateway.entrypoints=websecure"
      - "traefik.http.routers.api-gateway.tls=true"
      - "traefik.http.services.api-gateway.loadbalancer.server.port=80"

  ml-service:
    image: nginxdemos/hello:plain-text # แทนที่ด้วย image ของ FastAPI service ของคุณ
    container_name: omnisight-ml-service
    environment:
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      - MINIO_ENDPOINT=minio:9000
      - MINIO_ACCESS_KEY=${MINIO_ROOT_USER}
      - MINIO_SECRET_KEY=${MINIO_ROOT_PASSWORD}
      - MLFLOW_TRACKING_URI=http://mlflow:5000
    networks:
      - omnisight-net
    depends_on:
      - postgres
      - minio
      - mlflow
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.ml-service.rule=Host(`ml-api.${DOMAIN}`)"
      - "traefik.http.routers.ml-service.entrypoints=websecure"
      - "traefik.http.routers.ml-service.tls=true"
      - "traefik.http.services.ml-service.loadbalancer.server.port=80"
  
  frontend:
    image: nginxdemos/hello:plain-text # แทนที่ด้วย image ของ Next.js service ของคุณ
    container_name: omnisight-frontend
    environment:
      - NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
    networks:
      - omnisight-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(`app.${DOMAIN}`)"
      - "traefik.http.routers.frontend.entrypoints=websecure"
      - "traefik.http.routers.frontend.tls=true"
      - "traefik.http.services.frontend.loadbalancer.server.port=80"

  # ============================================================================
  # 6. ส่วนตรวจสอบและสังเกตการณ์ (OBSERVABILITY STACK)
  # ============================================================================
  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.95.0
    container_name: omnisight-otel-collector
    command: ["--config=/etc/otel-collector-config.yml"]
    volumes:
      - ./infra/opentelemetry/otel-collector-config.yml:/etc/otel-collector-config.yml
    networks:
      - omnisight-net

  jaeger:
    image: jaegertracing/all-in-one:1.53
    container_name: omnisight-jaeger
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    networks:
      - omnisight-net
    depends_on:
      - otel-collector
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.jaeger.rule=Host(`jaeger.${DOMAIN}`)"
      - "traefik.http.routers.jaeger.entrypoints=websecure"
      - "traefik.http.routers.jaeger.tls=true"
      - "traefik.http.services.jaeger.loadbalancer.server.port=16686" # Port ของ Jaeger UI

# ============================================================================
# การตั้งค่าระดับบนสุด
# ============================================================================
networks:
  omnisight-net:
    driver: bridge
    name: omnisight-net

volumes:
  postgres-data:
    name: omnisight-postgres-data
  minio-data:
    name: omnisight-minio-data
  label-studio-data:
    name: omnisight-label-studio-data
  n8n-data:
    name: omnisight-n8n-data
  jenkins-data:
    name: omnisight-jenkins-data
```

-----

## 5\. คู่มือเริ่มต้นใช้งาน (Getting Started Guide)

ทำตามขั้นตอนต่อไปนี้เพื่อเปิดใช้งานระบบ Project OmniSight ทั้งหมดบนเครื่องคอมพิวเตอร์ของคุณ

### สิ่งที่ต้องมี (Prerequisites)

  * **Docker & Docker Compose:** ตรวจสอบให้แน่ใจว่าคุณได้ติดตั้งเวอร์ชันล่าสุดแล้ว
  * **mkcert:** เครื่องมือสำหรับสร้างใบรับรอง (certificates) ที่เชื่อถือได้ในเครื่อง local ติดตั้งโดยทำตามคำแนะนำที่ [https://github.com/FiloSottile/mkcert](https://github.com/FiloSottile/mkcert)

-----

### ขั้นตอนที่ 1: สร้างใบรับรอง SSL สำหรับ Local 📜

ขั้นแรก ให้ติดตั้ง Certificate Authority (CA) ของ `mkcert` ในเครื่องของคุณ คำสั่งนี้ต้องทำเพียงครั้งเดียวต่อเครื่อง

```bash
mkcert -install
```

จากนั้น ไปยังไดเรกทอรีราก (root) ของโปรเจกต์ และสร้างใบรับรองสำหรับทุกเซอร์วิสที่กำหนดไว้ในไฟล์ `.env` ของคุณ ไฟล์เหล่านี้จะถูกเก็บไว้ในไดเรกทอรีที่ถูกต้องเพื่อให้ Traefik นำไปใช้

```bash
# ตรวจสอบให้แน่ใจว่าคุณอยู่ในไดเรกทอรีรากของโปรเจกต์
# คำสั่งนี้จะสร้าง wildcard certificate สำหรับ *.localhost
mkcert -cert-file ./infra/traefik/certs/local-cert.pem -key-file ./infra/traefik/certs/local-key.pem "localhost" "*.localhost"
```

### ขั้นตอนที่ 2: ตั้งค่าตัวแปรสภาพแวดล้อม (Environment Variables) ⚙️

คัดลอกไฟล์ตัวอย่าง environment เพื่อสร้างไฟล์คอนฟิกสำหรับเครื่องของคุณ

```bash
cp .env.example .env
```

เปิดไฟล์ `.env` และตรวจสอบตัวแปรต่างๆ ค่าเริ่มต้นถูกออกแบบมาให้ทำงานได้ทันที แต่คุณสามารถปรับเปลี่ยนรหัสผ่านหรือพอร์ตได้ตามต้องการ

-----

### ขั้นตอนที่ 3: เปิดใช้งานแพลตฟอร์ม 🚀

เมื่อสร้างใบรับรองและตั้งค่าสภาพแวดล้อมเรียบร้อยแล้ว ให้เปิดใช้งานระบบทั้งหมดในโหมด detached

```bash
docker compose up -d
```

การเปิดใช้งานครั้งแรกจะใช้เวลาสักครู่ เนื่องจาก Docker ต้องดาวน์โหลด container images ที่จำเป็นทั้งหมด การเปิดใช้งานครั้งต่อไปจะเร็วขึ้นมาก

-----

### ขั้นตอนที่ 4: การเข้าถึงเซอร์วิสต่างๆ 🌐

เมื่อคอนเทนเนอร์ทั้งหมดทำงานแล้ว คุณสามารถเข้าถึง UI ต่างๆ ผ่านเบราว์เซอร์ของคุณได้เลย ด้วย `mkcert` คุณควรจะเห็นสัญลักษณ์การเชื่อมต่อที่ปลอดภัย 🔒

| เซอร์วิส | URL | ชื่อผู้ใช้ (Username) | รหัสผ่าน (Password) |
| :--- | :--- | :--- | :--- |
| **OmniSight Frontend** | [https://app.localhost](https://www.google.com/search?q=https://app.localhost) | - | - |
| **OmniSight API** | [https://api.localhost](https://www.google.com/search?q=https://api.localhost) | - | - |
| **OmniSight ML API** | [https://ml-api.localhost](https://www.google.com/search?q=https://ml-api.localhost) | - | - |
| Traefik Dashboard | [https://traefik.localhost](https://www.google.com/search?q=https://traefik.localhost) | `admin` | `password` |
| MLflow | [https://mlflow.localhost](https://www.google.com/search?q=https://mlflow.localhost) | - | - |
| Prefect | [https://prefect.localhost](https://www.google.com/search?q=https://prefect.localhost) | - | - |
| Label Studio | [https://label-studio.localhost](https://www.google.com/search?q=https://label-studio.localhost) | - | - |
| n8n | [https://n8n.localhost](https://www.google.com/search?q=https://n8n.localhost) | *(ตั้งค่าในการเข้าใช้ครั้งแรก)* | *(ตั้งค่าในการเข้าใช้ครั้งแรก)* |
| Jenkins | [https://jenkins.localhost](https://www.google.com/search?q=https://jenkins.localhost) | `${JENKINS_ADMIN_USER}` | `${JENKINS_ADMIN_PASSWORD}` |
| MinIO Console | [https://minio.localhost](https://www.google.com/search?q=https://minio.localhost) | `${MINIO_ROOT_USER}` | `${MINIO_ROOT_PASSWORD}` |
| Adminer (DB UI) | [https://adminer.localhost](https://www.google.com/search?q=https://adminer.localhost) | `${POSTGRES_USER}` | `${POSTGRES_PASSWORD}` |
| Jaeger (Tracing) | [https://jaeger.localhost](https://www.google.com/search?q=https://jaeger.localhost) | - | - |
| Vault | [https://vault.localhost](https://www.google.com/search?q=https://vault.localhost) | Token: `${VAULT_DEV_ROOT_TOKEN_ID}` | - |
| Consul | [https://consul.localhost](https://www.google.com/search?q=https://consul.localhost) | - | - |
| Nomad | [https://nomad.localhost](https://www.google.com/search?q=https://nomad.localhost) | - | - |