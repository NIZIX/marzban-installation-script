# 🚀 Marzban Auto-Install Script
This script automates the installation and configuration of [Marzban](https://github.com/Gozargah/Marzban). It also sets up Nginx as a reverse proxy for Marzban and creates an admin user with sudo privileges.

## 🎯 Requirements
- 🖥️ Fresh Debian/Ubuntu server (recommended)
- 🔑 Sudo privileges
- 🌐 `git`

## ✨ Features
- Installs necessary dependencies.

- Provides a database selection:

  - `SQLite`

  - `MySQL`

  - `MariaDB`

- Installs Marzban.

- Configures Nginx as a reverse proxy.

## 💻 Usage
- Clone the repository to your server and run script with command:

```
git clone https://github.com/NIZIX/marzban-installation-script.git
cd marzban-installation-script
chmod +x marzban-script.sh
./marzban-script.sh
```
- Follow the on-screen instructions:

- Choose a database (SQLite, MySQL, or MariaDB). 

  - **ℹ️ If container starts after selection, press CTRL+C to continue**

- Enter your server's IP address or domain name.

- Create admin user for marzban.

- The Marzban page will be available at http://your-domain-or-ip/dashboard

## 🔍 Logs and Troubleshooting
`Marzban logs: /var/log/marzban/`

`Nginx logs: /var/log/nginx/`


---

# 🚀 Скрипт автоматической установки Marzban
Этот скрипт автоматизирует установку и настройку [Marzban](https://github.com/Gozargah/Marzban). 
Он также настраивает Nginx как обратный прокси для Marzban и создает администратора с правами sudo.

## 🎯 Требования
- 🖥️ Чистый сервер Debian/Ubuntu (рекомендуется)
- 🔑 Привилегии sudo
- 🌐 `git`

## ✨ Возможности
- Устанавливает необходимые зависимости.

- Предоставляет выбор базы данных:

  - `SQLite`

  - `MySQL`

  - `MariaDB`

- Устанавливает Marzban.

- Настраивает Nginx как обратный прокси.

## 💻 Использование
- Клонируйте репозиторий на ваш сервер и запустите скрипт командой:
```
git clone https://github.com/NIZIX/marzban-installation-script.git
cd marzban-installation-script
chmod +x marzban-script.sh
./marzban-script.sh
```
- Следуйте инструкциям на экране:

- Выберите базу данных (SQLite, MySQL или MariaDB). 

  - **ℹ️ Если контейнер запустится после выбора, нажмите CTRL+C для продолжения**

- Введите IP-адрес или доменное имя вашего сервера.

- Создайте администратора для Marzban.

- Страница Marzban будет доступна по адресу: `http://your-domain-or-ip/dashboard`

## 🔍 Логи и устранение неполадок
`Логи Marzban: /var/log/marzban/`

`Логи Nginx: /var/log/nginx/`
