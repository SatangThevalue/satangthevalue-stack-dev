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
        end

        API_FastAPI -- "เรียกข้อมูลจาก DB" --> Postgres;
        API_FastAPI -- "โหลดโมเดล (S3)" --> MinIO_API;
        API_FastAPI -- "ดึงข้อมูลลับ" --> Vault;

    end