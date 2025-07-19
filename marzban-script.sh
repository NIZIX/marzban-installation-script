#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo apt install -y curl git

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

eval "$install_command"

sudo apt install -y nginx

cd /etc/nginx/sites-available/

# Input IP/domain with validation
while true; do
    read -p "Enter VPS IP or domain (Ctrl+q to exit): " server_name
    if [[ "$server_name" == "" ]]; then
        echo "The field cannot be empty."
        continue
    fi
    if [[ "$server_name" == ^q ]]; then
        exit 0
    fi
    if [[ "$server_name" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        ip_parts=(${server_name//./ })
        valid_ip=1
        for part in "${ip_parts[@]}"; do
            if [[ "$part" -gt 255 ]]; then
                valid_ip=0
                break
            fi
        done
        if [[ $valid_ip -eq 0 ]]; then
            echo "Invalid IP address. Please enter a valid IP or domain."
            continue
        fi
    elif ! host "$server_name" &> /dev/null; then # Domain check
        echo "Invalid domain or IP address. Please enter a valid IP or domain."
        continue
    fi
    break
done

# Create the Nginx configuration file
cat << EOF > marzban
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


sudo ln -s /etc/nginx/sites-available/marzban /etc/nginx/sites-enabled/

sudo nginx -t

sudo systemctl restart nginx

echo
echo "Creating admin user for Marzban..."
marzban cli admin create --sudo

# --- Xray config generation ---
echo
echo "===== Запуск генератора конфига Xray ====="

# Возвращаемся в директорию скрипта, чтобы найти файл шаблона
cd - > /dev/null

TEMPLATE_FILE="xray_config.template.json"

# --- Шаг 1: Получаем Private Key ---
echo -n "1. Получение нового Private Key... "
# Выполняем команду, ищем строку с "Private key:", и берем третье слово из этой строки
PRIVATE_KEY=$(sudo docker exec marzban-marzban-1 xray x25519 | grep 'Private key:' | awk '{print $3}')

# Проверяем, что ключ получен
if [ -z "$PRIVATE_KEY" ]; then
    echo "ОШИБКА!"
    echo "Не удалось получить Private Key из контейнера. Убедитесь, что контейнер 'marzban-marzban-1' запущен."
else
    echo "OK"
fi

# --- Шаг 2: Генерируем Short ID ---
echo -n "2. Генерация нового Short ID... "
SHORT_ID=$(openssl rand -hex 8)
echo "OK"

# --- Шаг 3: Проверяем наличие шаблона ---
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ОШИБКА: Файл шаблона '$TEMPLATE_FILE' не найден. Убедитесь, что он лежит в той же папке, что и скрипт."
    exit 1
fi

# --- Шаг 4: Заменяем метки и создаем новый конфиг ---
echo -n "3. Создание нового конфига... "

# Создаем временный файл, чтобы не было проблем с правами доступа
TEMP_FILE=$(mktemp)

# Используем sed для замены
sed -e "s/\"PRIVATE_KEY_PLACEHOLDER\"/\"$PRIVATE_KEY\"/" \
    -e "s/\"SHORT_ID_PLACEHOLDER\"/\"$SHORT_ID\"/" \
    "$TEMPLATE_FILE" > "$TEMP_FILE"
echo "OK"

# --- Шаг 5: Копирование конфига в контейнер и перезапуск ---
echo -n "4. Копирование конфига в контейнер... "
sudo docker cp "$TEMP_FILE" marzban-marzban-1:/code/xray_config.json
if [ $? -eq 0 ]; then
    echo "OK"
else
    echo "ОШИБКА!"
    rm -f "$TEMP_FILE"
    exit 1
fi

rm -f "$TEMP_FILE"

echo -n "5. Перезапуск контейнера Marzban... "
sudo docker restart marzban-marzban-1
if [ $? -eq 0 ]; then
    echo "OK"
    echo "===== Готово ====="
else
    echo "ОШИБКА!"
    exit 1
fi
# --- End of Xray config generation ---


echo
echo
echo "The Marzban page will be available at http://$server_name/dashboard"
echo
echo
