#!/bin/sh

set -eu

PROJECT_NAME="KeyPulse"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info() {
    printf "${CYAN}[INFO]${RESET} %s\n" "$1"
}

success() {
    printf "${GREEN}[ OK ]${RESET} %s\n" "$1"
}

error() {
    printf "${RED}[ERROR]${RESET} %s\n" "$1"
}

warning() {
    printf "${YELLOW}[WARN]${RESET} %s\n" "$1"
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "Run this installer as root."
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="$ID"
        VERSION="$VERSION_ID"
    else
        error "Can't define OS."
        exit 1
    fi

    case "$OS" in
        debian|ubuntu)
            PACKAGE_MANAGER="apt"
            ;;
        *)
            error "OS $OS not supported."
            error "Supported OS: Debian and Ubuntu."
            exit 1
            ;;
    esac
}

install_dependencies_server() {
    info "Installing dependencies..."

    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        apt-get update
        apt-get install -y \
            openssh-server \
            curl \
            ca-certificates
    fi

    success "Dependencies installed."
}


install_dependencies_node() {
    info "Installing dependencies..."

    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        apt-get update
        apt-get install -y \
            sshpass \
            curl \
            ca-certificates
    fi

    success "Dependencies installed."
}

install_server() {
    printf "\n"
    printf "${CYAN}=== Installing KeyPulse Server ===${RESET}\n\n"

    install_dependencies_server

    info "Creating user for KeyPulse Server..."
    useradd -M -s /usr/sbin/nologin keypulse\
    warning "Write strong password for KeyPulse"
    warning "You can change it by command: passwd keypulse"
    passwd keypulse

    info "Installing KeyPulse Server..."
    mkdir -p /opt/keypulse-server/certs
    chown root:root /etc/keypulse-server
    chmod 755 /etc/keypulse-server
    chown keypulse:keypulse /etc/keypulse-server/certs
    chmod 755 /etc/keypulse-server/certs

    success "KeyPulse Server installed."
    warning "Настройте SFTP как сказано в инструкции на сайте, расположенной после ссылки скрипта"
    warning "Configure SFTP as described in the instructions on the website located after the script link."

    printf "\n"
}

install_node() {
    printf "\n"
    printf "${CYAN}=== Installing KeyPulse Node ===${RESET}\n\n"

    install_dependencies_node

    info "Installing KeyPulse Node..."

    mkdir -p /etc/keypulse
    cd /etc/keypulse
    wget https://github.com/HYXVEIL/keypulse/raw/refs/heads/main/keypulse.sh
    wget https://github.com/HYXVEIL/keypulse/raw/refs/heads/main/sync.sh
    wget https://github.com/HYXVEIL/keypulse/raw/refs/heads/main/config
    wget https://github.com/HYXVEIL/keypulse/raw/refs/heads/main/sftp_password
    mkdir certs
    sudo chmod +x /etc/keypulse/keypulse.sh
    sudo ln -s /etc/keypulse/keypulse.sh /usr/local/bin/keypulse
    
    cat > /etc/systemd/system/keypulse.service <<'EOF'
[Unit]
Description=KeyPulse synchronization service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/etc/keypulse/sync.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload

    success "KeyPulse Node installed."

    printf "\n"
}

show_menu() {
    clear

    printf "\n"
    printf "${CYAN}====================================${RESET}\n"
    printf "${CYAN}          KeyPulse Installer        ${RESET}\n"
    printf "${CYAN}====================================${RESET}\n"
    printf "\n"

    printf "Select component to install:\n\n"
    printf "  ${GREEN}1${RESET}) KeyPulse Server\n"
    printf "     Central server with actual certificates\n\n"

    printf "  ${GREEN}2${RESET}) KeyPulse Node\n"
    printf "     Client that sync certificates from central server\n\n"

    printf "  ${GREEN}3${RESET}) Exit\n\n"

    printf "Selection [1-3]: "
    read -r choice

    case "$choice" in
        1)
            install_server
            ;;
        2)
            install_node
            ;;
        3)
            info "Installation canceled."
            exit 0
            ;;
        *)
            error "Wrong selection."
            exit 1
            ;;
    esac
}

main() {
    require_root
    detect_os
    show_menu
}

main "$@"
