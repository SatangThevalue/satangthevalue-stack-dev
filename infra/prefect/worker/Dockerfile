# 1. ใช้ Image พื้นฐานของ Prefect
FROM prefecthq/prefect:latest

# -----------------------------------------------------------------
# ตั้งค่า Environment Variable สำหรับเวอร์ชั่น Vault
# -----------------------------------------------------------------
ENV VAULT_VERSION="1.17.3"

# -----------------------------------------------------------------
# สลับเป็น root เพื่อติดตั้ง dependencies
# -----------------------------------------------------------------
USER root

RUN apt-get update && apt-get install -y \
    # สำหรับ pg_dump และ pg_restore
    postgresql-client \
    \
    # สำหรับ rclone, vault, และ mc
    curl \
    \
    # สำหรับบีบอัดไฟล์
    gzip \
    \
    # สำหรับแตกไฟล์ Vault
    unzip \
    \
    # Utilities
    procps \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------
# 2. ติดตั้ง rclone (เหมือนเดิม)
# -----------------------------------------------------------------
RUN curl https://rclone.org/install.sh | bash

# -----------------------------------------------------------------
# 3. ติดตั้ง Vault CLI (เหมือนเดิม)
# -----------------------------------------------------------------
RUN curl -Lo /tmp/vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" \
    && unzip /tmp/vault.zip -d /usr/local/bin/ \
    && rm /tmp/vault.zip \
    && chmod +x /usr/local/bin/vault

# -----------------------------------------------------------------
# 4. ⭐️ ติดตั้ง MinIO Client (mc) (เพิ่มใหม่) ⭐️
# -----------------------------------------------------------------
RUN curl -Lo /usr/local/bin/mc "https://dl.min.io/client/mc/release/linux-amd64/mc" \
    && chmod +x /usr/local/bin/mc

# -----------------------------------------------------------------
# สลับกลับไปใช้ User 'prefect' เพื่อความปลอดภัย
# -----------------------------------------------------------------
USER prefect