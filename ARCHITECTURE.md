# System Architecture

สถาปัตยกรรมของ **satangthevalue-stack-dev** ถูกออกแบบมาเพื่อจำลองสภาพแวดล้อมการทำงานจริง (Production) ให้ใกล้เคียงที่สุด โดยยึดหลักการสำคัญดังนี้:

- **Single Entry Point:** ทราฟฟิกทั้งหมดจากภายนอกจะวิ่งผ่าน **Traefik Gateway** เพียงจุดเดียว ซึ่งทำหน้าที่เป็น Reverse Proxy และจัดการ SSL/TLS โดยอัตโนมัติ
- **Service Discovery:** Traefik สามารถค้นหาและกำหนดเส้นทางไปยังเซอร์วิสใหม่ๆ ที่ถูกเพิ่มเข้ามาใน Docker network ได้เองผ่าน Docker labels
- **Decoupled Services:** ทุกเซอร์วิสทำงานในคอนเทนเนอร์ของตัวเองและสื่อสารกันผ่านเน็ตเวิร์กภายใน ทำให้ง่ายต่อการบำรุงรักษาและอัปเดตแยกส่วน
- **Centralized Data:** ข้อมูลสำคัญถูกจัดเก็บไว้ที่ศูนย์กลาง เช่น PostgreSQL สำหรับข้อมูลเชิงสัมพันธ์ และ MinIO สำหรับ Object Storage

## แผนภาพสถาปัตยกรรม (Architecture Diagram)

แผนภาพนี้แสดงให้เห็นถึงการไหลของข้อมูล (Data Flow) และการเชื่อมต่อระหว่างเซอร์วิสต่างๆ ภายในระบบ

```mermaid
graph TD
    subgraph "ผู้ใช้งาน (localhost)"
        direction LR
        User -- "https://*.localhost" --> Traefik;
    end

    subgraph "Docker Network: satang-dev-net"
        direction TB

        Traefik -- "HTTPS" --> App_Frontend["app.localhost (Frontend)"];
        Traefik -- "HTTPS" --> App_Backend["api.localhost (Backend)"];
        
        App_Frontend -- "API Calls" --> App_Backend;

        subgraph "MLOps & Automation"
            MLflow["mlflow.localhost"];
            Prefect["prefect.localhost"];
            LabelStudio["label-studio.localhost"];
        end

        subgraph "Data Persistence"
            Postgres[("PostgreSQL")];
            MinIO[("MinIO S3 Storage")];
        end

        MLflow -- "Metadata" --> Postgres;
        MLflow -- "Artifacts" --> MinIO;
        Prefect -- "Backend Data" --> Postgres;
        LabelStudio -- "Datasets" --> MinIO;
        App_Backend -- "Data Access" --> Postgres;
        App_Backend -- "File Access" --> MinIO;
    end