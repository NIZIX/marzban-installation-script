#!/bin/bash

# --- Step 1: System Update and Dependency Installation ---
echo "===== Updating system and installing dependencies ====="
sudo apt update
sudo apt upgrade -y
# Install git, curl, and Nginx
sudo apt install -y curl git nginx

# --- Step 2: Marzban Installation ---
echo "===== Installing Marzban ====="
while true; do
    echo "Choose a database for Marzban:"
    echo "1. SQLite (default)"
    echo "2. MySQL"
    echo "3. MariaDB"
    read -p "Enter the option number (1-3, or press Enter for SQLite): " choice

    case $choice in
        1|"")
            install_command="sudo bash -c \"\$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)\" @ install"
            break
            ;;
        2)
            install_command="sudo bash -c \"\$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)\" @ install --database mysql"
            break
            ;;
        3)
            install_command="sudo bash -c \"\$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)\" @ install --database mariadb"
            break
            ;;
        *)
            echo "Invalid input. Please choose 1, 2, or 3."
            ;;
    esac
done

# Execute the Marzban installation command
eval "$install_command"

# --- Step 3: Nginx Configuration ---
echo "===== Configuring Nginx ====="
cd /etc/nginx/sites-available/

# Input for server's IP or domain name
while true; do
    read -p "Enter your server's IP or domain name: " server_name
    if [[ -z "$server_name" ]]; then
        echo "The field cannot be empty."
        continue
    fi
    # Basic validation for invalid characters
    if ! [[ "$server_name" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        echo "Invalid characters in domain or IP address."
        continue
    fi
    break
done

# Create the Nginx configuration file for Marzban
echo "Creating Nginx config for $server_name..."
cat << EOF | sudo tee marzban > /dev/null
server {
    listen 80;
    server_name $server_name;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Create a symbolic link to enable the site
sudo ln -s -f /etc/nginx/sites-available/marzban /etc/nginx/sites-enabled/

# Test Nginx configuration and restart the service
echo "Testing and restarting Nginx..."
sudo nginx -t
sudo systemctl restart nginx

# --- Step 4: Xray Configuration Generation ---
echo
echo "===== Generating Xray config ====="

OUTPUT_FILE="/var/lib/marzban/xray_config.json"

echo -n "1. Getting new Private Key... "
PRIVATE_KEY=""
# The container might take a moment to be ready, so we'll try a few times
for i in {1..5}; do
    PRIVATE_KEY=$(sudo docker exec marzban-marzban-1 xray x25519 2>/dev/null | grep 'Private key:' | awk '{print $3}')
    if [ -n "$PRIVATE_KEY" ]; then
        break
    fi
    echo -n "."
    sleep 2
done

if [ -z "$PRIVATE_KEY" ]; then
    echo " ERROR!"
    echo "Failed to get Private Key from the 'marzban-marzban-1' container."
    echo "Skipping Xray config generation. You may need to run it manually later."
else
    echo " OK"

    echo -n "2. Generating new Short ID... "
    SHORT_ID=$(openssl rand -hex 8)
    echo "OK"

    echo -n "3. Creating new config file... "
    TEMP_FILE=$(mktemp)

    # Create the Xray config from a heredoc
    cat << 'EOF' > "$TEMP_FILE"
{
    "log": {
      "loglevel": "warning"
    },
    "routing": {
      "rules": [
        {
          "ip": [
            "geoip:private"
          ],
          "outboundTag": "BLOCK",
          "type": "field"
        }
      ]
    },
    "inbounds": [
      {
        "tag": "VMESS TCP NOTLS",
        "listen": "0.0.0.0",
        "port": 445,
        "protocol": "vmess",
        "settings": {
          "clients": []
        },
        "streamSettings": {
          "network": "tcp",
          "tcpSettings": {},
          "security": "none"
        },
        "sniffing": {
          "enabled": true,
          "destOverride": [
            "http",
            "tls",
            "quic"
          ]
        }
      },
      {
        "tag": "TROJAN TCP NOTLS",
        "listen": "0.0.0.0",
        "port": 444,
        "protocol": "trojan",
        "settings": {
          "clients": []
        },
        "streamSettings": {
          "network": "tcp",
          "tcpSettings": {},
          "security": "none"
        },
        "sniffing": {
          "enabled": true,
          "destOverride": [
            "http",
            "tls",
            "quic"
          ]
        }
      },
      {
        "tag": "VLESS TCP REALITY",
        "listen": "0.0.0.0",
        "port": 443,
        "protocol": "vless",
        "settings": {
          "clients": [],
          "decryption": "none"
        },
        "streamSettings": {
          "network": "tcp",
          "tcpSettings": {},
          "security": "reality",
          "realitySettings": {
            "show": false,
            "dest": "github.com:443",
            "xver": 0,
            "serverNames": [
              "github.com"
            ],
            "privateKey": "PRIVATE_KEY_PLACEHOLDER",
            "shortIds": [
              "SHORT_ID_PLACEHOLDER"
            ]
          }
        },
        "sniffing": {
          "enabled": true,
          "destOverride": [
            "http",
            "tls",
            "quic"
          ]
        }
      },
      {
        "tag": "Shadowsocks TCP",
        "listen": "0.0.0.0",
        "port": 1080,
        "protocol": "shadowsocks",
        "settings": {
          "clients": [],
          "network": "tcp,udp"
        }
      }
    ],
    "outbounds": [
      {
        "protocol": "freedom",
        "tag": "DIRECT"
      },
      {
        "protocol": "blackhole",
        "tag": "BLOCK"
      }
    ]
  }
EOF

    # Replace placeholders with generated values
    sed -i.bak -e "s/\"PRIVATE_KEY_PLACEHOLDER\"/\"$PRIVATE_KEY\"/" \
        -e "s/\"SHORT_ID_PLACEHOLDER\"/\"$SHORT_ID\"/" \
        "$TEMP_FILE"
    rm -f "${TEMP_FILE}.bak"

    # Move the new config to the Marzban directory
    sudo mv "$TEMP_FILE" "$OUTPUT_FILE"

    if [ $? -eq 0 ]; then
        echo " SUCCESS!"
        echo "New config saved to: $OUTPUT_FILE"
        echo "Restarting Marzban to apply the new config..."
        sudo marzban restart
        echo "===== Done ====="
    else
        echo " ERROR!"
        echo "Failed to write file to $OUTPUT_FILE. Sudo permissions might be required."
        rm -f "$TEMP_FILE"
    fi
fi

# --- Step 5: Finalizing Setup ---
echo
echo "===== Creating Marzban Admin User ====="
marzban cli admin create --sudo

# # Display the generated config for the user to copy
# if [ -f "$OUTPUT_FILE" ]; then
#     echo
#     echo "********************************************************************************"
#     echo "********************* Xray Configuration (Core Settings) *********************"
#     echo "********************************************************************************"
#     echo
#     echo 
#     sudo cat "$OUTPUT_FILE"
#     echo
#     echo 
# fi

# # Display the final URL
# echo
# echo "================================================================================"
# echo "Please copy the config above and paste it into the Core Settings"
# echo "on the Marzban dashboard (gear icon in the top right corner)."
# echo "don't forget to save the changes and restart core"
echo "================================================================================"
echo "The Marzban dashboard is now available at: http://$server_name/dashboard"
echo "================================================================================"
echo
echo
