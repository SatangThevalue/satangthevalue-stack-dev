#!/bin/bash
set -e

# --- 1. ตรวจสอบ Environment Variables ---

# ตรวจสอบ Infisical
if [ -z "$INFISICAL_POSTGRES_USER" ] || [ -z "$INFISICAL_POSTGRES_PASSWORD" ] || [ -z "$INFISICAL_POSTGRES_DB" ]; then
  echo "ERROR: Infisical environment variables (INFISICAL_POSTGRES_USER, ...) must be set."
  exit 1
fi

# ตรวจสอบ Prefect
if [ -z "$PREFECT_POSTGRES_USER" ] || [ -z "$PREFECT_POSTGRES_PASSWORD" ] || [ -z "$PREFECT_POSTGRES_DB" ]; then
  echo "ERROR: Prefect environment variables (PREFECT_POSTGRES_USER, ...) must be set."
  exit 1
fi

# --- 2. รันคำสั่ง SQL ---
# เราเชื่อมต่อกับฐานข้อมูล 'postgres' (ซึ่งมีอยู่เสมอ) เพื่อสร้าง user และ database ใหม่
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL

    --- ========= INFISICAL SETUP ========= ---

    --- สร้าง User (Role) สำหรับ Infisical ---
    DO
    \$do\$
    BEGIN
       IF NOT EXISTS (
          SELECT FROM pg_catalog.pg_roles
          WHERE  rolname = '$INFISICAL_POSTGRES_USER') THEN

          CREATE ROLE $INFISICAL_POSTGRES_USER WITH LOGIN PASSWORD '$INFISICAL_POSTGRES_PASSWORD';
       ELSE
          RAISE NOTICE 'Role "%" already exists, skipping creation.', '$INFISICAL_POSTGRES_USER';
       END IF;
    END
    \$do\$;

    --- สร้าง Database สำหรับ Infisical ---
    SELECT 'CREATE DATABASE $INFISICAL_POSTGRES_DB'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$INFISICAL_POSTGRES_DB')\gexec

    --- (ตามคำขอ) สร้าง Database 'root' หากยังไม่มี ---
    SELECT 'CREATE DATABASE root'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'root')\gexec

    --- ให้สิทธิ์ (Grant Privileges) Infisical ---
    GRANT ALL PRIVILEGES ON DATABASE $INFISICAL_POSTGRES_DB TO $INFISICAL_POSTGRES_USER;
    
    --- ⭐️ [แก้ไข] มอบความเป็นเจ้าของ Database ให้ User ---
    ALTER DATABASE $INFISICAL_POSTGRES_DB OWNER TO $INFISICAL_POSTGRES_USER;


    --- ========= PREFECT SETUP ========= ---

    --- สร้าง User (Role) สำหรับ Prefect ---
    DO
    \$do\$
    BEGIN
       IF NOT EXISTS (
          SELECT FROM pg_catalog.pg_roles
          WHERE  rolname = '$PREFECT_POSTGRES_USER') THEN

          CREATE ROLE $PREFECT_POSTGRES_USER WITH LOGIN PASSWORD '$PREFECT_POSTGRES_PASSWORD';
       ELSE
          RAISE NOTICE 'Role "%" already exists, skipping creation.', '$PREFECT_POSTGRES_USER';
       END IF;
    END
    \$do\$;

    --- สร้าง Database สำหรับ Prefect ---
    SELECT 'CREATE DATABASE $PREFECT_POSTGRES_DB'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$PREFECT_POSTGRES_DB')\gexec

    --- ให้สิทธิ์ (Grant Privileges) Prefect ---
    GRANT ALL PRIVILEGES ON DATABASE $PREFECT_POSTGRES_DB TO $PREFECT_POSTGRES_USER;

    --- ⭐️ [แก้ไข] มอบความเป็นเจ้าของ Database ให้ User ---
    ALTER DATABASE $PREFECT_POSTGRES_DB OWNER TO $PREFECT_POSTGRES_USER;

EOSQL

# --- 3. แสดงข้อความสำเร็จ ---
echo "✅ Successfully created user '$INFISICAL_POSTGRES_USER' and database '$INFISICAL_POSTGRES_DB'."
echo "✅ Successfully created user '$PREFECT_POSTGRES_USER' and database '$PREFECT_POSTGRES_DB'."