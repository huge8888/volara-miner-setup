#!/bin/bash

# Automated Script: Volara-Miner Installation and Start with Proxy Support
# Credit: https://x.com/0xhuge

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Define icons
INFO_ICON="ℹ️"
SUCCESS_ICON="✅"
WARNING_ICON="⚠️"
ERROR_ICON="❌"

# Log file path
LOG_FILE="/var/log/volara_miner.log"

# Simple logo
show_logo() {
  echo -e "${BLUE}${BOLD}"
  echo "============================="
  echo "|  Welcome to Volara-Miner  |"
  echo "|        Setup Script       |"
  echo "============================="
  echo -e "${RESET}"
}

# Logging functions
log_info() {
  echo -e "${CYAN}${INFO_ICON} ${1}${RESET}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO] ${1}" >> "${LOG_FILE}"
}

log_success() {
  echo -e "${GREEN}${SUCCESS_ICON} ${1}${RESET}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [SUCCESS] ${1}" >> "${LOG_FILE}"
}

log_warning() {
  echo -e "${YELLOW}${WARNING_ICON} ${1}${RESET}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [WARNING] ${1}" >> "${LOG_FILE}"
}

log_error() {
  echo -e "${RED}${ERROR_ICON} ${1}${RESET}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') [ERROR] ${1}" >> "${LOG_FILE}"
}

# Proxy selection
select_proxy() {
  echo -e "${YELLOW}Please choose proxy type (http or socks5):${RESET}"
  echo "1. HTTP Proxy"
  echo "2. SOCKS5 Proxy"
  read -p "Enter choice [1-2]: " proxy_choice

  if [[ "$proxy_choice" -eq 1 ]]; then
    read -p "Enter your HTTP proxy (e.g., http://proxy-ip:port): " PROXY
    export PROXY
    log_info "Using HTTP proxy: $PROXY"
  elif [[ "$proxy_choice" -eq 2 ]]; then
    read -p "Enter your SOCKS5 proxy (e.g., socks5://proxy-ip:port): " PROXY
    export PROXY
    log_info "Using SOCKS5 proxy: $PROXY"
  else
    log_warning "Invalid selection, no proxy will be used."
  fi
}

# Update and upgrade system
update_system() {
  log_info "Updating and upgrading the system..."
  sudo apt update -y && sudo apt upgrade -y
}

# Install Docker
install_docker() {
  log_info "Installing Docker and dependencies..."
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo chmod +x /usr/local/bin/docker-compose

  docker --version &> /dev/null
  if [[ $? -eq 0 ]]; then
    log_success "Docker installed successfully."
  else
    log_error "Docker installation failed."
    exit 1
  fi
}

# Start Volara-Miner with Proxies
start_miner() {
  log_info "Ensure your Vana wallet has enough test tokens. Visit the faucet: https://faucet.vana.org/moksha"
  echo -e "${YELLOW}Note: Please check your Vana balance and claim Moksha test tokens before proceeding.${RESET}"

  read -sp "$(echo -e "${YELLOW}Enter your Metamask private key (hidden input): ${RESET}")" VANA_PRIVATE_KEY
  export VANA_PRIVATE_KEY

  if [[ -z "$VANA_PRIVATE_KEY" ]]; then
    log_error "Metamask private key cannot be empty. Please rerun the script and enter a valid key."
    exit 1
  fi

  log_info "Pulling the Volara-Miner Docker image..."
  docker pull volara/miner &> /dev/null
  if [[ $? -eq 0 ]]; then
    log_success "Docker image pulled successfully."
  else
    log_error "Failed to pull Docker image."
    exit 1
  fi

  log_info "Creating a Screen session with proxy..."
  if [[ -z "$PROXY" ]]; then
    screen -S volara -m bash -c "docker run -it -e VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY} volara/miner"
  else
    screen -S volara -m bash -c "docker run -it -e VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY} -e https_proxy=${PROXY} -e http_proxy=${PROXY} volara/miner"
  fi

  log_info "Connect to the Screen session: screen -r volara"
  log_info "Within the Screen session, follow on-screen instructions to complete Google and X login."

  log_success "Setup complete! Check your mining points at https://volara.xyz/"
}

# View Volara-Miner logs
view_miner_logs() {
  clear
  log_info "Displaying Volara-Miner logs..."
  docker ps --filter "ancestor=volara/miner" --format "{{.Names}}" | while read container_name
  do
    echo "Logs from container: $container_name"
    docker logs --tail 20 "$container_name"
    echo "--------------------------------------"
  done
}

# Menu display function
show_menu() {
  show_logo
  echo -e "${BOLD}${BLUE}==================== Volara-Miner Setup ====================${RESET}"
  echo "1. Fill Proxy Information (HTTP/SOCKS5)"
  echo "2. Update and Upgrade System"
  echo "3. Install Docker"
  echo "4. Start Volara-Miner with Proxy"
  echo "5. View Volara-Miner Logs"
  echo "6. Exit"
  echo -e "${BOLD}===========================================================${RESET}"
  echo -n "Select an option [1-6]: "
}

# Main loop
while true; do
  show_menu
  read -r choice
  case $choice in
    1)
      select_proxy
      ;;
    2)
      update_system
      ;;
    3)
      install_docker
      ;;
    4)
      start_miner
      ;;
    5)
      view_miner_logs
      ;;
    6)
      log_info "Exiting script, goodbye!"
      exit 0
      ;;
    *)
      log_warning "Invalid choice. Please select a valid option."
      ;;
  esac
done
