-- infra/postgres/initdb/01-init.sql
-- สคริปต์นี้จะทำงานอัตโนมัติเมื่อคอนเทนเนอร์ PostgreSQL ถูกสร้างขึ้นครั้งแรก

-- =================================================
-- สร้างผู้ใช้และฐานข้อมูลสำหรับแอปพลิเคชันหลัก
-- =================================================
-- สร้างผู้ใช้หลัก (ถ้ายังไม่มี)
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = '${POSTGRES_USER}') THEN

      CREATE ROLE "${POSTGRES_USER}" WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';
   END IF;
END
$do$;

-- สร้างฐานข้อมูลหลัก
SELECT 'CREATE DATABASE "${POSTGRES_DB}"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${POSTGRES_DB}')\gexec
GRANT ALL PRIVILEGES ON DATABASE "${POSTGRES_DB}" TO "${POSTGRES_USER}";

-- =================================================
-- สร้างผู้ใช้และฐานข้อมูลสำหรับ VAULT โดยเฉพาะ
-- =================================================
-- สร้างผู้ใช้สำหรับ Vault (ถ้ายังไม่มี)
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = '${VAULT_POSTGRES_USER}') THEN

      CREATE ROLE "${VAULT_POSTGRES_USER}" WITH LOGIN PASSWORD '${VAULT_POSTGRES_PASSWORD}';
   END IF;
END
$do$;

-- สร้างฐานข้อมูลสำหรับ Vault
SELECT 'CREATE DATABASE "${VAULT_POSTGRES_DB}"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${VAULT_POSTGRES_DB}')\gexec
GRANT ALL PRIVILEGES ON DATABASE "${VAULT_POSTGRES_DB}" TO "${VAULT_POSTGRES_USER}";


-- เข้าไปยังฐานข้อมูลหลักเพื่อสร้าง Schema (ถ้าจำเป็น)
\c ${POSTGRES_DB}
CREATE SCHEMA IF NOT EXISTS mlflow_store;
CREATE SCHEMA IF NOT EXISTS prefect_store;
CREATE SCHEMA IF NOT EXISTS app_data;

SELECT 'databases initialized successfully' as status;