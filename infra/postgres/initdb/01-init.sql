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