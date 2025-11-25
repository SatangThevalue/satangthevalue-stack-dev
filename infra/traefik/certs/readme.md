ขั้นตอนการสร้าง **Self-Signed Root CA** และ **Wildcard Certificate** เพื่อใช้เป็น **Default Certificate** ใน Traefik ครับ

วิธีนี้จะทำให้คุณมีใบรับรอง "กันตาย" (Backup) ที่มีอายุยาวนาน (เช่น 10 ปี) และรองรับทุก Subdomain (`*.yourdomain.com`) โดยเก็บไฟล์ไว้ที่ `infra/traefik/certs` ตามที่คุณต้องการ

-----

### ขั้นตอนที่ 1: สร้าง Script สำหรับออกใบรับรอง

เพื่อให้ง่ายและลดความผิดพลาด ผมแนะนำให้สร้าง Shell Script เล็กๆ เพื่อรันคำสั่ง OpenSSL ทีเดียวจบครับ

1.  **สร้างโฟลเดอร์เก็บข้อมูล (ถ้ายังไม่มี):**

    ```bash
    mkdir -p infra/traefik/certs
    cd infra/traefik/certs
    ```

2.  **สร้างไฟล์ config สำหรับ OpenSSL (`v3.ext`):**
    จำเป็นต้องทำเพื่อระบุว่านี่คือ Wildcard Cert (SAN - Subject Alternative Name)
    *(เปลี่ยน `yourdomain.com` เป็นโดเมนจริงของคุณ)*

    ```bash
    cat > v3.ext <<EOF
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
    subjectAltName = @alt_names

    [alt_names]
    DNS.1 = *.yourdomain.com
    DNS.2 = yourdomain.com
    EOF
    ```

3.  **รันคำสั่งสร้าง Certificate (ทีละบรรทัด):**

    ```bash
    # 1. สร้าง Root CA (Key และ Certificate) - อายุ 10 ปี
    # ระบบจะถามข้อมูล Country, Org ฯลฯ ใส่ตามใจชอบ
    openssl req -x509 -new -nodes -newkey rsa:4096 \
      -keyout rootCA.key -sha256 -days 3650 -out rootCA.crt \
      -subj "/C=TH/ST=Bangkok/L=Bangkok/O=MyInfra/CN=MyLocalRootCA"

    # 2. สร้าง Server Private Key (สำหรับ Traefik)
    openssl genrsa -out server.key 2048

    # 3. สร้าง CSR (Certificate Signing Request)
    openssl req -new -key server.key -out server.csr \
      -subj "/C=TH/ST=Bangkok/L=Bangkok/O=MyInfra/CN=*.yourdomain.com"

    # 4. ใช้ Root CA เซ็นรับรอง Server Cert โดยอ้างอิง v3.ext
    openssl x509 -req -in server.csr -CA rootCA.crt -CAkey rootCA.key \
      -CAcreateserial -out server.crt -days 3650 -sha256 -extfile v3.ext
    ```

**ผลลัพธ์ในโฟลเดอร์ `infra/traefik/certs`:**

  * `rootCA.crt`: เอาไปติดตั้งใน Browser/OS ของเครื่อง Client เพื่อให้ขึ้นกุญแจเขียว (Trusted)
  * `server.crt`: ไฟล์ Certificate ที่จะให้ Traefik ใช้
  * `server.key`: ไฟล์ Private Key ที่จะให้ Traefik ใช้ (ห้ามหาย ห้ามรั่วไหล)

-----

### ขั้นตอนที่ 2: ตั้งค่า Traefik ให้ใช้เป็น Default Certificate

ไปที่ไฟล์ **Dynamic Configuration** ของ Traefik (เช่น `config.yml` หรือ `tls.yml`) แล้วเพิ่มส่วน `stores` เข้าไปครับ

**ไฟล์: `infra/traefik/config.yml`** (หรือไฟล์ที่คุณ mount เข้าไปที่ `/etc/traefik/config.yml`)

```yaml
tls:
  stores:
    default:
      defaultCertificate:
        certFile: /etc/traefik/certs/server.crt
        keyFile:  /etc/traefik/certs/server.key

# (Optional) ถ้าต้องการให้ Traefik อ่าน primary cert จาก Vault ด้วย ให้ใส่ certificates list ต่อท้าย
#  certificates:
#    - certFile: /etc/traefik/certs/primary.crt
#      keyFile:  /etc/traefik/certs/primary.key
#      stores:
#        - default
```

-----

### ขั้นตอนที่ 3: ตรวจสอบ Docker Compose

ตรวจสอบให้แน่ใจว่าได้ Mount โฟลเดอร์ `infra/traefik/certs` เข้าไปใน Container Traefik แล้ว

**ไฟล์: `docker-compose.yml`**

```yaml
services:
  traefik:
    image: traefik:v3.0
    # ...
    volumes:
      # 1. Mount config ไฟล์ dynamic
      - ./infra/traefik/config.yml:/etc/traefik/config.yml:ro
      
      # 2. Mount โฟลเดอร์ certs ที่เราเพิ่งสร้าง
      - ./infra/traefik/certs:/etc/traefik/certs:ro
```

-----

### วิธีการนำไปใช้งาน (Client Side)

เพื่อให้ Browser (Chrome, Edge) หรือเครื่องคอมพิวเตอร์ของคุณเชื่อถือ Certificate นี้ (ขึ้นกุญแจสีเขียว ไม่ฟ้องว่า Not Secure):

1.  นำไฟล์ **`rootCA.crt`** จาก Server มาที่เครื่องคอมพิวเตอร์ของคุณ
2.  **Windows:** Double click ไฟล์ -\> Install Certificate -\> เลือก **"Trusted Root Certification Authorities"**
3.  **Mac:** Double click ไฟล์ -\> Keychain Access -\> Double click ที่ Cert ชื่อ "MyLocalRootCA" -\> เลือก Trust -\> **"Always Trust"**
4.  **Linux:** Copy ไปที่ `/usr/local/share/ca-certificates/` แล้วรัน `sudo update-ca-certificates`

เมื่อทำเสร็จแล้ว เวลาเข้าเว็บ `https://anything.yourdomain.com` Traefik จะส่ง Wildcard Cert นี้มา และ Browser 
ไฟล์ทั้ง 4 ตัวนี้เปรียบเสมือน "เอกสารและกุญแจ" ในระบบการยืนยันตัวตนดิจิทัล (PKI - Public Key Infrastructure) ครับ เพื่อให้เข้าใจง่าย ผมขอเปรียบเทียบกับ **"ระบบทำบัตรประชาชน"** ครับ

---

### 1. `rootCA.key` (สำคัญที่สุด ⛔️ ห้ามหาย ห้ามรั่วไหล)
* **คืออะไร:** **"ตรายางประทับตราของนายทะเบียน"** (Private Key ของผู้ออกใบรับรอง)
* **ความสำคัญ:** **ระดับสูงสุด (Top Secret)** ใครได้ไฟล์นี้ไป สามารถปลอมแปลงใบรับรองว่าเป็นเว็บของคุณได้ทุกเว็บ
* **การใช้งาน:** ใช้สำหรับ **"เซ็นอนุมัติ"** (Sign) ใบคำขอ (CSR) เพื่อเปลี่ยนให้เป็นใบรับรองฉบับจริง
* **เก็บที่ไหน:** เก็บไว้ในที่ปลอดภัยที่สุด (Offline หรือใน Vault) **ห้าม** นำไปใส่ใน Web Server หรือแจกจ่ายให้ใคร

### 2. `rootCA.crt` (แจกได้ 📢)
* **คืออะไร:** **"ประกาศนียบัตรรับรองนายทะเบียน"** (Public Certificate ของผู้ออกใบรับรอง)
* **ความสำคัญ:** สาธารณะ (Public)
* **การใช้งาน:**
    * **ฝั่ง Server:** ใช้เพื่อยืนยัน Chain (บางกรณี)
    * **ฝั่ง Client (สำคัญมาก):** ต้องนำไฟล์นี้ไป **ติดตั้ง (Install)** ลงใน Browser, Windows, Mac หรือ มือถือ ของผู้ใช้งาน เพื่อบอกอุปกรณ์เหล่านั้นว่า "ถ้าเจอเว็บไหนที่มีตราประทับจาก `rootCA.key` ให้เชื่อถือได้เลย (ขึ้นกุญแจสีเขียว)"
* **เก็บที่ไหน:** แจกจ่ายให้คนในทีม หรือติดตั้งลงเครื่องคอมพิวเตอร์ที่ต้องการเข้าเว็บ

### 3. `server.key` (ความลับเฉพาะเครื่อง 🔒)
* **คืออะไร:** **"กุญแจตู้เซฟของเว็บเรา"** (Private Key ของ Server)
* **ความสำคัญ:** ความลับ (Secret)
* **การใช้งาน:** ใช้คู่กับ `server.crt` เพื่อถอดรหัสข้อมูล HTTPS ที่ส่งเข้ามา
* **เก็บที่ไหน:** **ใส่ใน Traefik** (mount volume เข้าไป) หรือ Web Server อื่นๆ ห้ามแจกจ่าย

### 4. `server.csr` (เอกสารชั่วคราว 📝)
* **คืออะไร:** **"ใบคำร้องขอทำบัตรประชาชน"** (Certificate Signing Request)
    * ข้างในจะมีข้อมูลว่า "ฉันชื่อเว็บ `*.yourdomain.com` นะ นี่คือกุญแจสาธารณะของฉัน ช่วยเซ็นรับรองให้หน่อย"
* **ความสำคัญ:** ปานกลาง (ใช้แล้วทิ้งได้)
* **การใช้งาน:** เป็นตัวกลางที่สร้างมาจาก `server.key` เพื่อส่งไปให้ `rootCA` ทำการเซ็น (Sign)
* **ผลลัพธ์:** เมื่อนำ `server.csr` + `rootCA.key` + `rootCA.crt` มารวมร่างกันผ่านคำสั่ง OpenSSL เราจะได้ไฟล์ใหม่ชื่อ **`server.crt`** (ใบรับรองตัวจริง) ออกมาครับ

---

### สรุปภาพรวมการทำงาน (Flow)

1.  **สร้างแม่พิมพ์:** คุณสร้าง `rootCA.key` (ตรายาง) และ `rootCA.crt` (ใบประกาศ) ขึ้นมาก่อน
2.  **สร้างกุญแจบ้าน:** คุณสร้าง `server.key` (กุญแจเว็บ)
3.  **เขียนใบคำร้อง:** คุณใช้ `server.key` สร้าง `server.csr` (ใบคำร้อง)
4.  **อนุมัติ:** คุณใช้ `rootCA.key` (ตรายาง) ประทับตราลงบน `server.csr` (ใบคำร้อง)
5.  **ได้ผลลัพธ์:** กลายเป็น **`server.crt`** (บัตรประชาชนตัวจริง)
6.  **ใช้งาน:**
    * เอา **`server.key`** และ **`server.crt`** ไปใส่ใน **Traefik**
    * เอา **`rootCA.crt`** ไปใส่ใน **Chrome/Windows ของคุณ**

ดังนั้นใน Traefik `stores` config ที่เราทำไป เราจึงใช้แค่ `server.crt` (หรือ backup.crt) และ `server.key` (หรือ backup.key) ครับ ส่วน `server.csr` ลบทิ้งได้เลยเมื่อสร้างเสร็จ