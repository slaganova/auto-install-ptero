#!/bin/bash

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Конфигурация
VERSION="1.2.0"
TOKEN="2024"
TELEGRAM="@GamesHosting"
AUTHOR="Nur4ik818"

# Функция для отображения заголовка
display_header() {
  clear
  echo -e "${YELLOW}┌──────────────────────────────────────────────────────┐${NC}"
  echo -e "${YELLOW}│                                                      │${NC}"
  echo -e "${YELLOW}│${BLUE}          АВТОМАТИЧЕСКИЙ УСТАНОВЩИК ТЕМ               ${YELLOW}│${NC}"
  echo -e "${YELLOW}│${BLUE}                ДЛЯ ПТЕРОДАКТИЛЬ ${VERSION}                   ${YELLOW}│${NC}"
  echo -e "${YELLOW}│                                                      │${NC}"
  echo -e "${YELLOW}└──────────────────────────────────────────────────────┘${NC}"
  echo -e ""
}

# Функция для отображения статуса
display_status() {
  local status=$1
  local message=$2
  
  if [ "$status" = "success" ]; then
    echo -e "${GREEN}✔ ${message}${NC}"
  else
    echo -e "${RED}✖ ${message}${NC}"
  fi
}

# Функция для проверки root-доступа
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    display_status "error" "Этот скрипт должен быть запущен с правами root"
    exit 1
  fi
}

# Функция для отображения приветствия
display_welcome() {
  display_header
  echo -e "${CYAN}Добро пожаловать в автоматический установщик тем для Pterodactyl!${NC}"
  echo -e ""
  echo -e "${MAGENTA}▸ Версия: ${YELLOW}${VERSION}${NC}"
  echo -e "${MAGENTA}▸ Поддержка: ${YELLOW}${TELEGRAM}${NC}"
  echo -e "${MAGENTA}▸ Автор: ${YELLOW}${AUTHOR}${NC}"
  echo -e ""
  echo -e "${RED}⚠ Внимание: Свободное распространение этого скрипта запрещено!${NC}"
  echo -e ""
  read -n 1 -s -r -p "Нажмите любую клавишу для продолжения..."
  clear
}

# Установка зависимостей
install_dependencies() {
  display_header
  echo -e "${BLUE}Установка необходимых зависимостей...${NC}"
  echo -e ""
  
  apt update &> /dev/null
  if apt install -y jq curl wget unzip nodejs yarn &> /dev/null; then
    display_status "success" "Зависимости успешно установлены"
    sleep 1
  else
    display_status "error" "Ошибка при установке зависимостей"
    exit 1
  fi
}

# Проверка токена
check_token() {
  display_header
  echo -e "${BLUE}Проверка лицензионного кода...${NC}"
  echo -e ""
  
  local attempts=3
  while [ $attempts -gt 0 ]; do
    echo -e "${YELLOW}Введите лицензионный код (осталось попыток: $attempts):${NC}"
    read -r -s USER_TOKEN
    
    if [ "$USER_TOKEN" = "$TOKEN" ]; then
      display_status "success" "Лицензионный код принят"
      sleep 1
      return 0
    else
      attempts=$((attempts-1))
      display_status "error" "Неверный код. Осталось попыток: $attempts"
    fi
  done
  
  echo -e "${RED}Доступ запрещен. Пожалуйста, свяжитесь с ${TELEGRAM}${NC}"
  exit 1
}

# Меню выбора темы
theme_menu() {
  while true; do
    display_header
    echo -e "${BLUE}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                  ВЫБЕРИТЕ ТЕМУ                      │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} 1. ${YELLOW}Stellar${NC} - современная светлая тема                 ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 2. ${YELLOW}Billing${NC} - тема с интеграцией биллинга              ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 3. ${YELLOW}Enigma${NC} - темная загадочная тема                    ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}                                                  ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} x. ${RED}Выход в главное меню${NC}                              ${BLUE}│${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────┘${NC}"
    echo -e ""
    
    read -p "Введите номер темы (1-3/x): " choice
    
    case $choice in
      1) install_theme "stellar" ;;
      2) install_theme "billing" ;;
      3) install_theme "enigma" ;;
      x) return ;;
      *) 
        echo -e "${RED}Неверный выбор. Пожалуйста, попробуйте снова.${NC}"
        sleep 1
        ;;
    esac
  done
}

# Установка темы
install_theme() {
  local theme=$1
  display_header
  echo -e "${BLUE}Начало установки темы ${YELLOW}${theme}${BLUE}...${NC}"
  echo -e ""
  
  # Создаем временную директорию
  local temp_dir="/tmp/pterodactyl_theme_${theme}"
  mkdir -p "$temp_dir"
  
  # Скачиваем тему
  echo -e "${CYAN}▸ Скачивание темы...${NC}"
  if wget -q "https://github.com/Nur4ik00p/Auto-Install-Thema-Pterodactyl/raw/main/${theme}.zip" -O "${temp_dir}/${theme}.zip"; then
    display_status "success" "Тема успешно загружена"
  else
    display_status "error" "Ошибка при загрузке темы"
    return 1
  fi
  
  # Распаковываем
  echo -e "${CYAN}▸ Распаковка архива...${NC}"
  if unzip -q -o "${temp_dir}/${theme}.zip" -d "$temp_dir"; then
    display_status "success" "Архив успешно распакован"
  else
    display_status "error" "Ошибка при распаковке"
    return 1
  fi
  
  # Копируем файлы
  echo -e "${CYAN}▸ Установка файлов темы...${NC}"
  if cp -rf "${temp_dir}/pterodactyl/"* "/var/www/pterodactyl"; then
    display_status "success" "Файлы темы успешно скопированы"
  else
    display_status "error" "Ошибка при копировании файлов"
    return 1
  fi
  
  # Устанавливаем зависимости Node.js
  echo -e "${CYAN}▸ Установка Node.js зависимостей...${NC}"
  curl -sL https://deb.nodesource.com/setup_16.x | bash - &> /dev/null
  apt install -y nodejs &> /dev/null
  npm install -g yarn &> /dev/null
  
  # Собираем ассеты
  echo -e "${CYAN}▸ Компиляция ассетов...${NC}"
  cd /var/www/pterodactyl || return 1
  yarn add react-feather &> /dev/null
  
  # Для темы billing нужны дополнительные команды
  if [ "$theme" = "billing" ]; then
    php artisan billing:install stable &> /dev/null
  fi
  
  php artisan migrate --force &> /dev/null
  yarn build:production &> /dev/null
  php artisan view:clear &> /dev/null
  
  # Очистка
  rm -rf "$temp_dir"
  
  echo -e ""
  echo -e "${GREEN}┌──────────────────────────────────────────────────────┐${NC}"
  echo -e "${GREEN}│          ТЕМА УСПЕШНО УСТАНОВЛЕНА!                   │${NC}"
  echo -e "${GREEN}└──────────────────────────────────────────────────────┘${NC}"
  echo -e ""
  
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
}

# Восстановление панели
repair_panel() {
  display_header
  echo -e "${YELLOW}Восстановление стандартной темы Pterodactyl...${NC}"
  echo -e ""
  
  if bash <(curl -s https://raw.githubusercontent.com/Nur4ik00p/Auto-Install-Thema-Pterodactyl/main/repair.sh); then
    echo -e ""
    echo -e "${GREEN}Панель успешно восстановлена!${NC}"
  else
    echo -e ""
    echo -e "${RED}Ошибка при восстановлении панели${NC}"
  fi
  
  echo -e ""
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
}

# Настройка Wings
configure_wings() {
  display_header
  echo -e "${BLUE}Настройка Wings...${NC}"
  echo -e ""
  
  read -p "Введите токен для настройки Wings: " wings_token
  echo -e ""
  
  if eval "$wings_token" && systemctl start wings; then
    echo -e "${GREEN}Wings успешно настроен и запущен!${NC}"
  else
    echo -e "${RED}Ошибка при настройке Wings${NC}"
  fi
  
  echo -e ""
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
}

# Создание узла
create_node() {
  display_header
  echo -e "${BLUE}Создание нового узла...${NC}"
  echo -e ""
  
  read -p "Введите название локации: " location_name
  read -p "Введите описание локации: " location_description
  read -p "Введите домен: " domain
  read -p "Введите имя узла: " node_name
  read -p "Введите ОЗУ (в МБ): " ram
  read -p "Введите дисковое пространство (в МБ): " disk_space
  read -p "Введите ID локации: " locid
  
  cd /var/www/pterodactyl || { echo "Ошибка: Директория не найдена"; return; }
  
  echo -e "${CYAN}Создание локации...${NC}"
  php artisan p:location:make <<EOF
$location_name
$location_description
EOF
  
  echo -e "${CYAN}Создание узла...${NC}"
  php artisan p:node:make <<EOF
$node_name
$location_description
$locid
https
$domain
yes
no
no
$ram
$ram
$disk_space
$disk_space
100
8080
2022
/var/lib/pterodactyl/volumes
EOF
  
  echo -e ""
  echo -e "${GREEN}Узел и локация успешно созданы!${NC}"
  echo -e ""
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
}

# Удаление панели
uninstall_panel() {
  display_header
  echo -e "${RED}┌──────────────────────────────────────────────────────┐${NC}"
  echo -e "${RED}│         УДАЛЕНИЕ ПАНЕЛИ PTERODACTYL                  │${NC}"
  echo -e "${RED}└──────────────────────────────────────────────────────┘${NC}"
  echo -e ""
  echo -e "${YELLOW}Это действие необратимо! Вы уверены, что хотите продолжить?${NC}"
  echo -e ""
  
  read -p "Введите 'DELETE' для подтверждения: " confirmation
  if [ "$confirmation" != "DELETE" ]; then
    echo -e "${BLUE}Удаление отменено.${NC}"
    sleep 1
    return
  fi
  
  echo -e ""
  echo -e "${RED}Начало удаления панели...${NC}"
  if bash <(curl -s https://pterodactyl-installer.se) <<< $'y\ny\ny\ny'; then
    echo -e "${GREEN}Панель успешно удалена!${NC}"
  else
    echo -e "${RED}Ошибка при удалении панели${NC}"
  fi
  
  echo -e ""
  read -n 1 -s -r -p "Нажмите любую клавишу для завершения..."
  exit 0
}

# Создание администратора
create_admin() {
  display_header
  echo -e "${BLUE}Создание администратора...${NC}"
  echo -e ""
  
  read -p "Введите имя пользователя: " username
  read -p "Введите email: " email
  read -s -p "Введите пароль: " password
  echo -e ""
  
  cd /var/www/pterodactyl || { echo "Ошибка: Директория не найдена"; return; }
  
  if php artisan p:user:make <<EOF
yes
$email
$username
$username
$username
$password
EOF
  then
    echo -e ""
    echo -e "${GREEN}Администратор успешно создан!${NC}"
  else
    echo -e ""
    echo -e "${RED}Ошибка при создании администратора${NC}"
  fi
  
  echo -e ""
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
}

# Смена пароля VPS
change_vps_password() {
  display_header
  echo -e "${BLUE}Смена пароля VPS...${NC}"
  echo -e ""
  
  read -s -p "Введите новый пароль: " password
  echo -e ""
  read -s -p "Повторите пароль: " password_confirm
  echo -e ""
  
  if [ "$password" != "$password_confirm" ]; then
    echo -e "${RED}Пароли не совпадают!${NC}"
    sleep 1
    return
  fi
  
  if echo -e "$password\n$password" | passwd; then
    echo -e "${GREEN}Пароль успешно изменен!${NC}"
  else
    echo -e "${RED}Ошибка при смене пароля${NC}"
  fi
  
  echo -e ""
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
}

# Главное меню
main_menu() {
  while true; do
    display_header
    echo -e "${BLUE}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                  ГЛАВНОЕ МЕНЮ                       │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} 1. ${YELLOW}Установка тем${NC}                                   ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 2. ${YELLOW}Восстановление панели${NC}                          ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 3. ${YELLOW}Настройка Wings${NC}                                ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 4. ${YELLOW}Создание узла${NC}                                  ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 5. ${YELLOW}Создание администратора${NC}                       ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 6. ${YELLOW}Смена пароля VPS${NC}                               ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 7. ${RED}Удаление панели${NC}                                ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}                                                  ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 0. ${RED}Выход${NC}                                        ${BLUE}│${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────┘${NC}"
    echo -e ""
    
    read -p "Выберите действие (0-7): " choice
    
    case $choice in
      1) theme_menu ;;
      2) repair_panel ;;
      3) configure_wings ;;
      4) create_node ;;
      5) create_admin ;;
      6) change_vps_password ;;
      7) uninstall_panel ;;
      0) 
        echo -e "${BLUE}Завершение работы...${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}Неверный выбор. Пожалуйста, попробуйте снова.${NC}"
        sleep 1
        ;;
    esac
  done
}

# Основной код
check_root
display_welcome
install_dependencies
check_token
main_menu
