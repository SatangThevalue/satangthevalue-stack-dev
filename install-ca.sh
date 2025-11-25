#!/bin/bash
set -e

# --- ตรวจสอบว่ารันด้วย sudo ---
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  echo "Usage: sudo ./install-ca.sh"
  exit 1
fi

# ที่อยู่ของไฟล์ Certificate (เทียบจากที่รันสคริปต์)
CERT_PATH="./infra/vault/keys/CA/${DOMAIN}_ca.crt"

if [ ! -f "$CERT_PATH" ]; then
    echo "❌ Error: Certificate file not found at $CERT_PATH"
    echo "Please ensure vault-init.sh has run and created the file."
    exit 1
fi

OS_NAME=$(uname -s)

case "$OS_NAME" in
    ###################################
    # macOS
    ###################################
    Darwin)
        echo "🍎 Detected macOS..."
        echo "Installing cert to System Keychain (requires password)..."
        security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CERT_PATH"
        echo "✅ macOS: Certificate 'My Local Dev CA' installed and trusted."
        ;;

    ###################################
    # Linux
    ###################################
    Linux)
        echo "🐧 Detected Linux..."

        # --- ตรวจจับ WSL (Windows Subsystem for Linux) ---
        if grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null; then
            echo "⚠️ Detected WSL. This script cannot install certs into the Windows Host Trust Store."
            echo "You must install the certificate from Windows (PowerShell)."
            echo ""
            echo "Run this command in an 'Administrator PowerShell' terminal:"
            # แปลง Path (เช่น ./vault_keys/ca.crt) ให้เป็น Windows Path
            WIN_PATH=$(wslpath -w "$CERT_PATH")
            echo "Import-Certificate -FilePath \"$WIN_PATH\" -CertStoreLocation \"Cert:\LocalMachine\Root\""
            exit 1

        # --- Debian/Ubuntu ---
        elif [ -f /etc/debian_version ]; then
            echo "Distro: Debian/Ubuntu based."
            DEST_FILE="/usr/local/share/ca-certificates/my-local-dev-ca.crt"
            cp "$CERT_PATH" "$DEST_FILE"
            echo "Updating certificate store..."
            update-ca-certificates
            echo "✅ Linux (Debian): Certificate installed."

        # --- Red Hat/Fedora ---
        elif [ -f /etc/redhat-release ]; then
            echo "Distro: Red Hat/Fedora based."
            DEST_FILE="/etc/pki/ca-trust/source/anchors/my-local-dev-ca.crt"
            cp "$CERT_PATH" "$DEST_FILE"
            echo "Updating certificate trust..."
            update-ca-trust
            echo "✅ Linux (Red Hat): Certificate installed."

        else
            echo "❌ Error: Unsupported Linux distribution."
            echo "Please install '$CERT_PATH' manually."
            exit 1
        fi
        ;;

    ###################################
    # OS อื่นๆ (เช่น Windows Git Bash)
    ###################################
    *)
        echo "❌ Error: Unsupported OS ($OS_NAME)."
        echo "This script only supports macOS and Linux."
        echo "For Windows, please use PowerShell."
        exit 1
        ;;
esac

echo "---"
echo "🎉 Success! The CA is now trusted by your OS."
echo "⚠️ You may need to RESTART your web browser (Chrome, Firefox, etc.) for changes to take effect."