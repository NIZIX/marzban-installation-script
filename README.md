# 🚀 Marzban Auto-Install Script
This script automates the installation and configuration of Marzban. It also sets up Nginx as a reverse proxy for Marzban and creates an admin user with sudo privileges.

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
- Clone the repository to your server, and run script:

```
git clone https://github.com/NIZIX/marzban-script.git
cd marzban-script
chmod +x marzban-install.sh
./marzban-install.sh
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
