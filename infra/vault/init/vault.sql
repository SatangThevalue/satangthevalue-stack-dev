-- --- 1. ส่วนของการจัดการ Database (Optional) ---
-- หมายเหตุ: ใน Docker ถ้ากำหนด POSTGRES_DB=vault ใน docker-compose แล้ว
-- ไม่จำเป็นต้องรันคำสั่ง CREATE DATABASE นี้ซ้ำ (เพราะมันจะ Error ว่ามีอยู่แล้ว)
-- แต่ถ้ารันมือ หรือ Database ยังไม่ถูกสร้าง ให้ uncomment บรรทัดล่างนี้:

-- CREATE DATABASE vault ENCODING 'UTF8';


-- --- 2. ส่วนของการสร้าง Tables (Schema) ---
-- ควร connect เข้า database 'vault' ก่อนรันส่วนนี้
-- หรือใส่คำสั่ง \c vault ถ้าใช้ psql command line

-- 2.1 สร้างตาราง KV Store
CREATE TABLE IF NOT EXISTS vault_kv_store (
    parent_path TEXT COLLATE "C" NOT NULL,
    path        TEXT COLLATE "C",
    key         TEXT COLLATE "C",
    value       BYTEA,
    CONSTRAINT vault_kv_store_pkey PRIMARY KEY (path, key)
);

-- 2.2 สร้าง Index เพื่อความเร็วในการค้นหา
CREATE INDEX IF NOT EXISTS parent_path_idx ON vault_kv_store (parent_path);

-- 2.3 สร้างตารางสำหรับ HA (High Availability) Locks
CREATE TABLE IF NOT EXISTS vault_ha_locks (
    ha_key      TEXT COLLATE "C" NOT NULL,
    ha_identity TEXT COLLATE "C" NOT NULL,
    ha_value    TEXT COLLATE "C",
    valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT vault_ha_locks_pkey PRIMARY KEY (ha_key)
);


-- --- 3. ส่วนของการจัดการสิทธิ์ (Permissions) ---
-- เปลี่ยน 'vault_user' เป็นชื่อ User ที่คุณใช้งานจริง (เช่น POSTGRES_USER ใน .env)
-- หากคุณล็อกอินด้วย User นั้นอยู่แล้ว ไม่ต้องรันคำสั่ง GRANT เหล่านี้ก็ได้

GRANT ALL PRIVILEGES ON DATABASE vault TO vault;
GRANT ALL PRIVILEGES ON TABLE vault_kv_store TO vault;
GRANT ALL PRIVILEGES ON TABLE vault_ha_locks TO vault;