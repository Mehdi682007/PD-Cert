#!/usr/bin/env bash

set -euo pipefail

# ==============================
# Colors
# ==============================
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

print_banner() {
  echo -e "${CYAN}${BOLD}"
  echo "┌────────────────────────────────────────────────────────┐"
  echo "│                                                        │"
  echo "│   ____  ____             ____          _               │"
  echo "│  |  _ \|  _ \           / ___|___ _ __| |_             │"
  echo "│  | |_) | | | |  _____  | |   / _ \ '__| __|            │"
  echo "│  |  __/| |_| | |_____| | |__|  __/ |  | |_             │"
  echo "│  |_|   |____/           \____\___|_|   \__|            │"
  echo "│                                                        │"
  echo "│        Let's Encrypt SSL via Cloudflare DNS            │"
  echo "│                                                        │"
  echo "└────────────────────────────────────────────────────────┘"
  echo -e "${RESET}"
}

error_exit() {
  echo -e "${RED}❌ Error:${RESET} $1"
  exit 1
}

success_msg() {
  echo -e "${GREEN}✅ $1${RESET}"
}

info_msg() {
  echo -e "${BLUE}ℹ️  $1${RESET}"
}

warn_msg() {
  echo -e "${YELLOW}⚠️  $1${RESET}"
}

print_success_box() {
  echo
  echo -e "${GREEN}${BOLD}"
  echo "┌────────────────────────────────────────────────────────┐"
  echo "│                                                        │"
  echo "│   ✅ Operation completed successfully                  │"
  echo "│                                                        │"
  echo "└────────────────────────────────────────────────────────┘"
  echo -e "${RESET}"
}

print_banner

if [[ "$EUID" -ne 0 ]]; then
  error_exit "Please run this script as root or with sudo. Example: sudo bash cloudflare-ssl.sh"
fi

if ! command -v apt >/dev/null 2>&1; then
  error_exit "This script currently supports Ubuntu/Debian-based systems only."
fi

echo -e "${BOLD}Choose action:${RESET}"
echo -e "  ${GREEN}1) 🚀  Issue / renew certificate${RESET}"
echo -e "  ${YELLOW}2) ♻️  Delete existing certificate, then issue again${RESET}"
echo -e "  ${RED}3) 🗑️  Delete existing certificate only${RESET}"
echo -e "  ${CYAN}4) 📅 Show certificate remaining days${RESET}"
echo -e "  ${BLUE}5) 🚪 Exit${RESET}"
echo

read -rp "Enter option [1-5]: " ACTION

if [[ "$ACTION" != "1" && "$ACTION" != "2" && "$ACTION" != "3" && "$ACTION" != "4" && "$ACTION" != "5" ]]; then
  error_exit "Invalid action."
fi

if [[ "$ACTION" == "5" ]]; then
  echo
  info_msg "Exit selected. No changes were made."
  exit 0
fi

echo
read -rp "🌐 Enter your domain, example: example.com: " DOMAIN

if [[ -z "$DOMAIN" ]]; then
  error_exit "Domain cannot be empty."
fi

delete_certificate() {
  local domain="$1"

  echo
  info_msg "Checking existing certificates..."
  certbot certificates || true

  if [[ ! -d "/etc/letsencrypt/live/${domain}" ]]; then
    echo
    warn_msg "No certificate directory found for: ${domain}"
    warn_msg "Path not found: /etc/letsencrypt/live/${domain}"
    return 0
  fi

  echo
  warn_msg "This will delete the certificate for: ${domain}"
  echo -e "${YELLOW}Paths that may be removed by Certbot:${RESET}"
  echo "  /etc/letsencrypt/live/${domain}"
  echo "  /etc/letsencrypt/archive/${domain}"
  echo "  /etc/letsencrypt/renewal/${domain}.conf"
  echo

  read -rp "Type DELETE to continue: " CONFIRM_DELETE

  if [[ "$CONFIRM_DELETE" != "DELETE" ]]; then
    error_exit "Delete cancelled."
  fi

  certbot delete --cert-name "$domain" --non-interactive || {
    echo
    error_exit "Certbot delete failed. Check the exact certificate name with: sudo certbot certificates"
  }

  echo
  success_msg "Certificate deleted successfully."
}

check_auto_renewal_status() {
  echo
  echo -e "${BOLD}🔁 Automatic renewal status:${RESET}"

  if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-unit-files certbot.timer >/dev/null 2>&1; then
      if systemctl list-unit-files certbot.timer | grep -q "certbot.timer"; then
        echo
        info_msg "certbot.timer was found."

        if systemctl is-enabled certbot.timer >/dev/null 2>&1; then
          success_msg "certbot.timer is enabled."
        else
          warn_msg "certbot.timer is not enabled. Trying to enable it..."
          systemctl enable certbot.timer >/dev/null 2>&1 || warn_msg "Could not enable certbot.timer automatically."
        fi

        if systemctl is-active certbot.timer >/dev/null 2>&1; then
          success_msg "certbot.timer is active."
        else
          warn_msg "certbot.timer is not active. Trying to start it..."
          systemctl start certbot.timer >/dev/null 2>&1 || warn_msg "Could not start certbot.timer automatically."
        fi

        echo
        info_msg "Next Certbot timer runs:"
        systemctl list-timers certbot.timer --no-pager || true
        return 0
      fi
    fi
  fi

  echo
  warn_msg "certbot.timer was not found via systemd."

  if [[ -f "/etc/cron.d/certbot" ]]; then
    success_msg "Certbot cron job found at: /etc/cron.d/certbot"
    return 0
  fi

  if [[ -f "/etc/cron.daily/certbot" ]]; then
    success_msg "Certbot daily cron job found at: /etc/cron.daily/certbot"
    return 0
  fi

  warn_msg "No certbot.timer or Certbot cron job was detected."
  warn_msg "Certbot package usually creates one automatically on Ubuntu/Debian."
  warn_msg "You can still test renewal manually with: certbot renew --dry-run"
}

install_certbot() {
  echo
  info_msg "Installing Certbot and Cloudflare DNS plugin..."
  apt update
  apt install -y certbot python3-certbot-dns-cloudflare
  success_msg "Certbot and Cloudflare plugin installed."

  check_auto_renewal_status
}

show_remaining_days() {
  local domain="$1"
  local cert_file="/etc/letsencrypt/live/${domain}/fullchain.pem"

  echo
  info_msg "Checking certificate remaining days for: ${domain}"

  if [[ ! -f "$cert_file" ]]; then
    echo
    error_exit "Certificate file not found: ${cert_file}"
  fi

  if ! command -v openssl >/dev/null 2>&1; then
    error_exit "openssl is not installed. Please install openssl and try again."
  fi

  local end_date
  local expiry_epoch
  local current_epoch
  local seconds_left
  local days_left

  end_date="$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)"

  if [[ -z "$end_date" ]]; then
    error_exit "Could not read certificate expiration date."
  fi

  expiry_epoch="$(date -d "$end_date" +%s)"
  current_epoch="$(date +%s)"
  seconds_left=$((expiry_epoch - current_epoch))
  days_left=$((seconds_left / 86400))

  echo
  echo -e "${BOLD}📜 Certificate:${RESET} ${domain}"
  echo -e "${BOLD}📁 File:${RESET} ${cert_file}"
  echo -e "${BOLD}⏳ Expiry date:${RESET} ${end_date}"

  if [[ "$seconds_left" -lt 0 ]]; then
    echo -e "${RED}${BOLD}❌ Status: Expired${RESET}"
    echo -e "${RED}${BOLD}📅 Days remaining: ${days_left}${RESET}"
  elif [[ "$days_left" -le 7 ]]; then
    echo -e "${RED}${BOLD}⚠️  Days remaining: ${days_left}${RESET}"
    warn_msg "Certificate is close to expiry."
  elif [[ "$days_left" -le 30 ]]; then
    echo -e "${YELLOW}${BOLD}📅 Days remaining: ${days_left}${RESET}"
    warn_msg "Certificate renewal should happen automatically if Certbot renewal is active."
  else
    echo -e "${GREEN}${BOLD}📅 Days remaining: ${days_left}${RESET}"
    success_msg "Certificate is valid."
  fi

  check_auto_renewal_status
}

issue_certificate() {
  echo
  read -rp "📧 Enter your email for Let's Encrypt notifications: " EMAIL

  if [[ -z "$EMAIL" ]]; then
    error_exit "Email cannot be empty."
  fi

  echo
  echo -e "${BOLD}Choose certificate type:${RESET}"
  echo -e "  ${CYAN}1) 🔒 Main domain only:${RESET} ${DOMAIN}"
  echo -e "  ${CYAN}2) 🌍 Main domain + www:${RESET} ${DOMAIN}, www.${DOMAIN}"
  echo -e "  ${CYAN}3) ⭐ Wildcard:${RESET} ${DOMAIN}, *.${DOMAIN}"
  echo

  read -rp "Enter option [1-3]: " CERT_TYPE

  if [[ "$CERT_TYPE" != "1" && "$CERT_TYPE" != "2" && "$CERT_TYPE" != "3" ]]; then
    error_exit "Invalid certificate type."
  fi

  echo
  read -rsp "🔑 Enter your Cloudflare API Token: " CF_API_TOKEN
  echo

  if [[ -z "$CF_API_TOKEN" ]]; then
    error_exit "Cloudflare API Token cannot be empty."
  fi

  CREDENTIALS_FILE="/etc/letsencrypt/cloudflare.ini"

  echo
  info_msg "Creating Cloudflare credentials file..."
  mkdir -p /etc/letsencrypt

  cat > "$CREDENTIALS_FILE" <<EOF
dns_cloudflare_api_token = ${CF_API_TOKEN}
EOF

  chown root:root "$CREDENTIALS_FILE"
  chmod 600 "$CREDENTIALS_FILE"

  success_msg "Cloudflare credentials file created securely."
  echo
  info_msg "Requesting certificate..."

  CERTBOT_BASE_CMD=(
    certbot certonly
    --dns-cloudflare
    --dns-cloudflare-credentials "$CREDENTIALS_FILE"
    --email "$EMAIL"
    --agree-tos
    --non-interactive
  )

  case "$CERT_TYPE" in
    1)
      "${CERTBOT_BASE_CMD[@]}" \
        -d "$DOMAIN"
      ;;
    2)
      "${CERTBOT_BASE_CMD[@]}" \
        -d "$DOMAIN" \
        -d "www.$DOMAIN"
      ;;
    3)
      "${CERTBOT_BASE_CMD[@]}" \
        -d "$DOMAIN" \
        -d "*.$DOMAIN"
      ;;
  esac

  echo
  success_msg "Certificate issued successfully."
  echo
  echo -e "${BOLD}📁 Certificate paths:${RESET}"
  echo -e "  ${GREEN}Full chain:${RESET} /etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
  echo -e "  ${GREEN}Private key:${RESET} /etc/letsencrypt/live/${DOMAIN}/privkey.pem"

  echo
  info_msg "Testing automatic renewal..."
  certbot renew --dry-run

  success_msg "Renewal dry-run completed."

  check_auto_renewal_status

  echo
  echo -e "${BOLD}Use these paths in Nginx/Apache:${RESET}"
  echo
  echo "ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;"
  echo "ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;"

  show_remaining_days "$DOMAIN"
}

case "$ACTION" in
  1)
    install_certbot
    issue_certificate
    ;;
  2)
    install_certbot
    delete_certificate "$DOMAIN"
    issue_certificate
    ;;
  3)
    install_certbot
    delete_certificate "$DOMAIN"
    echo
    success_msg "Done. Certificate deleted only."
    ;;
  4)
    show_remaining_days "$DOMAIN"
    ;;
esac

print_success_box
