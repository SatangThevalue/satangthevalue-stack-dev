#!/bin/bash
set -e

# --- 1. ตรวจสอบ Environment Variables ---

# ตรวจสอบ Prefect
if [ -z "$PREFECT_POSTGRES_USER" ] || [ -z "$PREFECT_POSTGRES_PASSWORD" ] || [ -z "$PREFECT_POSTGRES_DB" ]; then
  echo "ERROR: Prefect environment variables (PREFECT_POSTGRES_USER, ...) must be set."
  exit 1
fi

# ตรวจสอบ MLflow
if [ -z "$MLFLOW_POSTGRES_USER" ] || [ -z "$MLFLOW_POSTGRES_PASSWORD" ] || [ -z "$MLFLOW_POSTGRES_DB" ]; then
  echo "ERROR: MLflow environment variables (MLFLOW_POSTGRES_USER, ..._PASSWORD, ..._DB) must be set."
  exit 1
fi

# ตรวจสอบ Vault
if [ -z "$VAULT_POSTGRES_USER" ] || [ -z "$VAULT_POSTGRES_PASSWORD" ] || [ -z "$VAULT_POSTGRES_DB" ]; then
  echo "ERROR: Vault environment variables (VAULT_POSTGRES_USER, ..._PASSWORD, ..._DB) must be set."
  exit 1
fi

# ตรวจสอบ Loki
if [ -z "$LOKI_DB_USER" ] || [ -z "$LOKI_DB_PASSWORD" ] || [ -z "$LOKI_DB_NAME" ]; then
  echo "ERROR: Loki environment variables (LOKI_DB_USER, ..._PASSWORD, ..._NAME) must be set."
  exit 1
fi


# --- 2. รันคำสั่ง SQL ---
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL

    --- (ตามคำขอ) สร้าง Database 'root' หากยังไม่มี ---
    SELECT 'CREATE DATABASE root'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'root')\gexec


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

    --- มอบความเป็นเจ้าของ Database ให้ User ---
    ALTER DATABASE $PREFECT_POSTGRES_DB OWNER TO $PREFECT_POSTGRES_USER;


    --- ========= 🧪 MLFLOW SETUP ========= ---

    --- สร้าง User (Role) สำหรับ MLflow ---
    DO
    \$do\$
    BEGIN
       IF NOT EXISTS (
          SELECT FROM pg_catalog.pg_roles
          WHERE  rolname = '$MLFLOW_POSTGRES_USER') THEN

          CREATE ROLE $MLFLOW_POSTGRES_USER WITH LOGIN PASSWORD '$MLFLOW_POSTGRES_PASSWORD';
       ELSE
          RAISE NOTICE 'Role "%" already exists, skipping creation.', '$MLFLOW_POSTGRES_USER';
       END IF;
    END
    \$do\$;

    --- สร้าง Database สำหรับ MLflow ---
    SELECT 'CREATE DATABASE $MLFLOW_POSTGRES_DB'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$MLFLOW_POSTGRES_DB')\gexec

    --- ให้สิทธิ์ (Grant Privileges) MLflow ---
    GRANT ALL PRIVILEGES ON DATABASE $MLFLOW_POSTGRES_DB TO $MLFLOW_POSTGRES_USER;

    --- มอบความเป็นเจ้าของ Database ให้ User ---
    ALTER DATABASE $MLFLOW_POSTGRES_DB OWNER TO $MLFLOW_POSTGRES_USER;


    --- ========= 🛡️ VAULT SETUP ========= ---

    --- สร้าง User (Role) สำหรับ Vault ---
    DO
    \$do\$
    BEGIN
       IF NOT EXISTS (
          SELECT FROM pg_catalog.pg_roles
          WHERE  rolname = '$VAULT_POSTGRES_USER') THEN

          CREATE ROLE $VAULT_POSTGRES_USER WITH LOGIN PASSWORD '$VAULT_POSTGRES_PASSWORD';
       ELSE
          RAISE NOTICE 'Role "%" already exists, skipping creation.', '$VAULT_POSTGRES_USER';
       END IF;
    END
    \$do\$;

    --- สร้าง Database สำหรับ Vault ---
    SELECT 'CREATE DATABASE $VAULT_POSTGRES_DB'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$VAULT_POSTGRES_DB')\gexec

    --- ให้สิทธิ์ (Grant Privileges) Vault ---
    GRANT ALL PRIVILEGES ON DATABASE $VAULT_POSTGRES_DB TO $VAULT_POSTGRES_USER;

    --- มอบความเป็นเจ้าของ Database ให้ User ---
    ALTER DATABASE $VAULT_POSTGRES_DB OWNER TO $VAULT_POSTGRES_USER;


    --- ========= 🪵 LOKI SETUP ========= ---

    --- สร้าง User (Role) สำหรับ Loki ---
    DO
    \$do\$
    BEGIN
       IF NOT EXISTS (
          SELECT FROM pg_catalog.pg_roles
          WHERE  rolname = '$LOKI_DB_USER') THEN

          CREATE ROLE $LOKI_DB_USER WITH LOGIN PASSWORD '$LOKI_DB_PASSWORD';
       ELSE
          RAISE NOTICE 'Role "%" already exists, skipping creation.', '$LOKI_DB_USER';
       END IF;
    END
    \$do\$;

    --- สร้าง Database สำหรับ Loki ---
    SELECT 'CREATE DATABASE $LOKI_DB_NAME'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$LOKI_DB_NAME')\gexec

    --- ให้สิทธิ์ (Grant Privileges) Loki ---
    GRANT ALL PRIVILEGES ON DATABASE $LOKI_DB_NAME TO $LOKI_DB_USER;

    --- มอบความเป็นเจ้าของ Database ให้ User ---
    ALTER DATABASE $LOKI_DB_NAME OWNER TO $LOKI_DB_USER;


EOSQL

# --- 3. แสดงข้อความสำเร็จ ---
echo "✅ Successfully created user '$PREFECT_POSTGRES_USER' and database '$PREFECT_POSTGRES_DB'."
echo "✅ Successfully created user '$MLFLOW_POSTGRES_USER' and database '$MLFLOW_POSTGRES_DB'."
echo "✅ Successfully created user '$VAULT_POSTGRES_USER' and database '$VAULT_POSTGRES_DB'."
echo "✅ Successfully created user '$LOKI_DB_USER' and database '$LOKI_DB_NAME'."