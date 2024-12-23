#!/bin/bash

# =======================================
#           WeeWX All-in-One Script
# =======================================
# Dieses Script wurde von Staubi erstellt
# und automatisiert die Installation und
# Einrichtung von WeeWX sowie zusätzlicher
# Erweiterungen.

echo -e "\n\e[36m=======================================\e[0m"
echo -e "\e[36m           WeeWX All-in-One Script\e[0m"
echo -e "\e[36m=======================================\e[0m"
echo -e "\e[34mDieses Script wurde von Staubi erstellt.\e[0m"
echo -e "\e[34mEs automatisiert die Installation und Einrichtung\e[0m"
echo -e "\e[34mvon WeeWX sowie zusätzlicher Erweiterungen.\n\e[0m"

set -e

# Funktion, um den Status einer Aufgabe anzuzeigen
show_status() {
  local step="$1"
  local status="$2"
  if [ "$status" == "done" ]; then
    echo -e "\e[32m✔ $step\e[0m"
  elif [ "$status" == "current" ]; then
    echo -ne "\e[33m⏳ $step\e[0m\r"
  else
    echo "$step"
  fi
}

# Schritte definieren
steps=(
  "System updaten und upgraden"
  "Benötigte Pakete installieren"
  "Zeitzone auf Berlin setzen"
  "Deutsche Spracheinstellungen aktivieren"
  "WeeWX-Repository und Key hinzufügen"
  "Paketliste aktualisieren und WeeWX installieren"
  "GW1000-Erweiterung installieren"
  "Belchertown-Skin installieren"
  "MQTT-Erweiterung installieren"
  "WDC-Erweiterung installieren"
  "Dienstüberwachung einrichten"
)

# Schritte ausführen
for i in "${!steps[@]}"; do
  step="${steps[$i]}"
  show_status "$step" "current"

  case $i in
    0)
      sudo apt-get update -qq > /dev/null && sudo apt-get upgrade -y -qq > /dev/null
      ;;
    1)
      sudo apt-get install -y -qq python3-ephem python3-pcapy unzip gnupg gpg python3-paho-mqtt > /dev/null
      ;;
    2)
      sudo timedatectl set-timezone Europe/Berlin > /dev/null
      ;;
    3)
      sudo sed -i 's/^# *de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && sudo locale-gen > /dev/null && sudo update-locale LANG=de_DE.UTF-8 > /dev/null
      ;;
    4)
      wget -qO - https://weewx.com/keys.html | sudo gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg > /dev/null
      echo "deb [arch=all] https://weewx.com/apt/python3 buster main" | sudo tee /etc/apt/sources.list.d/weewx.list > /dev/null
      ;;
    5)
      sudo apt-get update && sudo apt-get install -y weewx
      ;;
    6)
      wget -q https://github.com/gjr80/weewx-gw1000/releases/download/v0.6.3/gw1000.zip > /dev/null
      sudo weectl extension install gw1000.zip -y > /dev/null
      ;;
    7)
      wget -q https://github.com/poblabs/weewx-belchertown/releases/download/weewx-belchertown-1.3.1/weewx-belchertown-release.1.3.1.tar.gz > /dev/null
      sudo weectl extension install weewx-belchertown-release.1.3.1.tar.gz -y > /dev/null
      ;;
    8)
      wget -q -O weewx-mqtt.zip https://github.com/matthewwall/weewx-mqtt/archive/master.zip > /dev/null
      sudo weectl extension install weewx-mqtt.zip -y > /dev/null
      ;;
    9)
      wget -q -O "/tmp/weewx-wdc.zip" https://github.com/Daveiano/weewx-wdc/releases/download/v3.5.1/weewx-wdc-v3.5.1.zip > /dev/null
      mkdir -p /tmp/weewx-wdc/ > /dev/null
      unzip -qq /tmp/weewx-wdc.zip -d /tmp/weewx-wdc/ > /dev/null
      sudo weectl extension install -y /tmp/weewx-wdc/ > /dev/null
      ;;
    10)
      sudo sed -i '/\[Service\]/a Restart=always\nRestartSec=60' /usr/lib/systemd/system/weewx.service > /dev/null
      sudo systemctl daemon-reload > /dev/null
      ;;
  esac

  show_status "$step" "done"
  sleep 1

done

# Neustart von WeeWX optional anbieten
read -p "Soll 'systemctl restart weewx' ausgeführt werden? (y/n): " choice
if [ "$choice" == "y" ]; then
  sudo systemctl restart weewx
  echo "WeeWX wurde neu gestartet."
else
  echo "WeeWX wurde nicht neu gestartet."
fi
