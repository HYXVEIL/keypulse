#!/bin/bash

SERVICE="keypulse"

while true; do
    clear

    echo "=============================="
    echo "        KeyPulse Manager"
    echo "=============================="
    echo

    if systemctl is-active --quiet "$SERVICE"; then
        STATUS="● Active/Запущен"
    else
        STATUS="● Stopped/Остановлен"
    fi

    echo "Status: $STATUS"
    echo
    echo "1) Start/Запустить"
    echo "2) Stop/Остановить"
    echo "3) Restart/Перезапустить"
    echo "4) Exit/Выход"
    echo
    read -rp "Select action/Выберите действие [1-4]: " choice

    case "$choice" in
        1)
            sudo systemctl start "$SERVICE"
            echo "KeyPulse started."
            sleep 2
            ;;
        2)
            sudo systemctl stop "$SERVICE"
            echo "KeyPulse stopped."
            sleep 2
            ;;
        3)
            sudo systemctl restart "$SERVICE"
            echo "KeyPulse restarted."
            sleep 2
            ;;
        4)
            clear
            exit 0
            ;;
        *)
            echo "Wrong selection."
            sleep 2
            ;;
    esac
done
