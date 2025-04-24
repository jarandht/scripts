#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____ _    ________   ____             __     ____           __        ____ 
   / __ \ |  / / ____/  / __ \____  _____/ /_   /  _/___  _____/ /_____ _/ / / 
  / /_/ / | / / __/    / /_/ / __ \/ ___/ __/   / // __ \/ ___/ __/ __ `/ / /  
 / ____/| |/ / /___   / ____/ /_/ (__  ) /_   _/ // / / (__  ) /_/ /_/ / / /   
/_/     |___/_____/  /_/    \____/____/\__/  /___/_/ /_/____/\__/\__,_/_/_/   

EOF
}

RD=$(echo "\033[01;31m")   # Red color
YW=$(echo "\033[33m")      # Yellow color
GN=$(echo "\033[1;92m")    # Green color
CL=$(echo "\033[m")        # Clear color
BFR="\\r\\033[K"           # Back to the previous line
HOLD="-"
CM="${GN}✓${CL}"           # Checkmark
CROSS="${RD}✗${CL}"        # Cross

set -euo pipefail
shopt -s inherit_errexit nullglob

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

# Add OAuth realm configuration
add_oauth_realm() {
  local realm_name="$1"
  local client_id="$2"
  local client_secret="$3"
  local redirect_uri="$4"

  echo "Creating OAuth realm: ${realm_name}"
  
  # Create a new OAuth realm configuration
  cat <<EOF >/etc/pve/realm.cfg
realm: $realm_name
client_id: $client_id
client_secret: $client_secret
redirect_uri: $redirect_uri
EOF
  
  msg_ok "Added OAuth realm: ${realm_name}"
}

start_routines() {
  header_info

  # Prompt for Proxmox VE sources
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SOURCES" --menu "The package manager will use the correct sources to update and install packages on your Proxmox VE server.\n \nCorrect Proxmox VE sources?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Correcting Proxmox VE Sources"
    cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
    echo 'APT::Get::Update::SourceListWarnings::NonFreeFirmware "false";' >/etc/apt/apt.conf.d/no-bookworm-firmware.conf
    msg_ok "Corrected Proxmox VE Sources"
    ;;
  no)
    msg_error "Selected no to Correcting Proxmox VE Sources"
    ;;
  esac

  # Disable 'pve-enterprise' repository
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PVE-ENTERPRISE" --menu "The 'pve-enterprise' repository is only available to users who have purchased a Proxmox VE subscription.\n \nDisable 'pve-enterprise' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Disabling 'pve-enterprise' repository"
    cat <<EOF >/etc/apt/sources.list.d/pve-enterprise.list
# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
EOF
    msg_ok "Disabled 'pve-enterprise' repository"
    ;;
  no)
    msg_error "Selected no to Disabling 'pve-enterprise' repository"
    ;;
  esac

  # Enable 'pve-no-subscription' repository
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PVE-NO-SUBSCRIPTION" --menu "The 'pve-no-subscription' repository provides access to all of the open-source components of Proxmox VE.\n \nEnable 'pve-no-subscription' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Enabling 'pve-no-subscription' repository"
    cat <<EOF >/etc/apt/sources.list.d/pve-install-repo.list
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
    msg_ok "Enabled 'pve-no-subscription' repository"
    ;;
  no)
    msg_error "Selected no to Enabling 'pve-no-subscription' repository"
    ;;
  esac

  # Correct 'ceph package repositories'
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "CEPH PACKAGE REPOSITORIES" --menu "The 'Ceph Package Repositories' provides access to both the 'no-subscription' and 'enterprise' repositories (initially disabled).\n \nCorrect 'ceph package sources?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Correcting 'ceph package repositories'"
    cat <<EOF >/etc/apt/sources.list.d/ceph.list
# deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise
# deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
# deb https://enterprise.proxmox.com/debian/ceph-reef bookworm enterprise
# deb http://download.proxmox.com/debian/ceph-reef bookworm no-subscription
EOF
    msg_ok "Corrected 'ceph package repositories'"
    ;;
  no)
    msg_error "Selected no to Correcting 'ceph package repositories'"
    ;;
  esac

  # Add 'pvetest' repository
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PVETEST" --menu "The 'pvetest' repository can give advanced users access to new features and updates before they are officially released.\n \nAdd (Disabled) 'pvetest' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Adding 'pvetest' repository and set disabled"
    cat <<EOF >/etc/apt/sources.list.d/pvetest-for-beta.list
# deb http://download.proxmox.com/debian/pve bookworm pvetest
EOF
    msg_ok "Added 'pvetest' repository"
    ;;
  no)
    msg_error "Selected no to Adding 'pvetest' repository"
    ;;
  esac

  # Disable subscription nag
  if [[ ! -f /etc/apt/apt.conf.d/no-nag-script ]]; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUBSCRIPTION NAG" --menu "This will disable the nag message reminding you to purchase a subscription every time you log in to the web interface.\n \nDisable subscription nag?" 14 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Support Subscriptions" "Supporting the software's development team is essential. Check their official website's Support Subscriptions for pricing. Without their dedicated work, we wouldn't have this exceptional software." 10 58
      msg_info "Disabling subscription nag"
      echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 0 ]; then sed -i '/get_string/ s/True/False/' /usr/share/proxmox-widget-toolkit/proxmoxlib.js; fi\"; };" > /etc/apt/apt.conf.d/no-nag-script
      msg_ok "Disabled subscription nag"
      ;;
    no)
      msg_error "Selected no to Disabling subscription nag"
      ;;
    esac
  fi

  # Update apt cache
  msg_info "Updating APT Cache"
  apt-get update -y
  msg_ok "Updated APT Cache"

  # Upgrade packages
  msg_info "Upgrading Packages"
  apt-get upgrade -y
  msg_ok "Upgraded Packages"

  # Install necessary packages
  msg_info "Installing Necessary Packages"
  apt-get install -y curl wget vim htop sshpass ca-certificates lm-sensors
  msg_ok "Installed Necessary Packages"

  # Remove unused packages
  msg_info "Removing Unused Packages"
  apt-get autoremove -y
  msg_ok "Removed Unused Packages"

  # Reboot the server
  msg_info "Rebooting the server"
  reboot
}

# Run the script
start_routines