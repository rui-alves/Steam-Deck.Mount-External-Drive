#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/rui-alves/Steam-Deck.Mount-External-Drive
# Use at own Risk!

#curl -sSL https://raw.githubusercontent.com/rui-alves/Steam-Deck.Mount-External-Drive/main/curl_install.sh | bash

#stop running script if anything returns an error (non-zero exit )
set -e

repo_url="https://raw.githubusercontent.com/rui-alves/Steam-Deck.Mount-External-Drive/main"
repo_lib_dir="$repo_url/lib"

tmp_dir="/tmp/scawp.SDMED.install"

rules_install_dir="/etc/udev/rules.d"
service_install_dir="/etc/systemd/system"

# CHANGED: install globally instead of /home/deck/.local/share/...
script_install_dir="/usr/local/lib/scawp/SDMED"

device_name="$(uname --nodename)"
user_uid="$(id -u)"

# CHANGED: remove hard dependency on user "deck" (non-SteamDeck systems won't have it)
# Keep a safety prompt when not on a stock Steam Deck (steamdeck hostname + UID 1000)
if [ "$device_name" != "steamdeck" ] || [ "$user_uid" != "1000" ]; then
  zenity --question --width=450 \
  --text="This code was originally written for Steam Deck (hostname: steamdeck, user UID: 1000). \
  \nIt appears you are running on a different system/non-standard configuration. \
  \nThis fork installs SDMED globally at: $script_install_dir \
  \nAre you sure you want to continue?"
  if [ "$?" != 0 ]; then
    #NOTE: This code will never be reached due to \"set -e\", the system will already exit for us but just incase keep this
    echo "bye then! xxx"
    exit 1;
  fi
fi

function install_automount () {
  zenity --question --width=400 \
    --text="Read $repo_url/README.md before proceeding. \
  \nDo you want to install the Auto-Mount Service?"
  if [ "$?" != 0 ]; then
    #NOTE: This code will never be reached due to "set -e", the system will already exit for us but just incase keep this
    echo "bye then! xxx"
    exit 0;
  fi

  echo "Making tmp folder $tmp_dir"
  mkdir -p "$tmp_dir"

  echo "Downloading Required Files"
  curl -o "$tmp_dir/automount.sh" "$repo_url/automount.sh"
  curl -o "$tmp_dir/external-drive-mount@.service" "$repo_lib_dir/external-drive-mount@.service"
  curl -o "$tmp_dir/99-steamos-automount.rules" "$repo_lib_dir/99-steamos-automount.rules"

  echo "Making script folder $script_install_dir"
  sudo mkdir -p "$script_install_dir"

  echo "Copying $tmp_dir/automount.sh to $script_install_dir/automount.sh"
  sudo cp "$tmp_dir/automount.sh" "$script_install_dir/automount.sh"

  echo "Adding Execute and Removing Write Permissions"
  sudo chmod 555 "$script_install_dir/automount.sh"

  echo "Copying $tmp_dir/99-steamos-automount.rules to $rules_install_dir/99-steamos-automount.rules"
  sudo cp "$tmp_dir/99-steamos-automount.rules" "$rules_install_dir/99-steamos-automount.rules"
  
  #remove old rules if installed
  if [ -f "$rules_install_dir/99-external-drive-mount.rules" ]; then
    sudo rm "$rules_install_dir/99-external-drive-mount.rules"
  fi
  
  if [ -f "$rules_install_dir/98-external-drive-mount.rules" ]; then
    sudo rm "$rules_install_dir/98-external-drive-mount.rules"
  fi

  echo "Copying $tmp_dir/external-drive-mount@.service to $service_install_dir/external-drive-mount@.service"
  sudo cp "$tmp_dir/external-drive-mount@.service" "$service_install_dir/external-drive-mount@.service"

  # NEW (minimal robustness): ensure udisks2 is enabled on distros where it's not preset-enabled
  echo "Enabling udisks2 (required for automount)"
  sudo systemctl enable --now udisks2.service || true

  echo "Reloading Services"
  sudo udevadm control --reload
  sudo systemctl daemon-reload
}

install_automount

zenity --question --width=400 \
  --text="Restart Required to take effect, \
\nDo you want to Restart Now?"
if [ "$?" != 0 ]; then
  #NOTE: This code will never be reached due to "set -e", the system will already exit for us but just incase keep this
  echo "bye then! xxx"
  exit 0;
fi

reboot

echo "Done."
