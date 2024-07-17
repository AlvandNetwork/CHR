#!/bin/bash
clear
TERM_WIDTH=$(tput cols)

# Color id
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[38;5;68m'
GREEN='\033[38;5;35m'
YELLOW='\033[1;33m'
END='\033[0m'

# Function to center text
center_text() {
    local text="$1"
    local text_length=${#text}
    local padding=$(( (TERM_WIDTH - text_length) / 2 ))
    printf "%${padding}s%s\n" "" "$text"
}

# Loading animation
loading() {
    local duration=2
    local interval=0.2
    local chars="/-\|"

    for ((i = 0; i < duration; i++)); do
        for ((j = 0; j < ${#chars}; j++)); do
            echo -ne "\r Loading... ${chars:$j:1}"
            sleep $interval
        done
    done
    echo -ne "\r"
}

# Call the loading function
loading

# Get the OS version
OS_VERSION=$(lsb_release -ds)

# Check OS version and display a warning if not Ubuntu 20 or 22
if [[ "$OS_VERSION" != "Ubuntu 20.04 LTS" && "$OS_VERSION" != "Ubuntu 22.04 LTS" && "$OS_VERSION" != "Ubuntu 20.04.6 LTS" ]]; then
    echo -e "${RED}$(center_text 'Error: This script is only compatible with Ubuntu 20.04 and 22.04.')${END}"
    exit 1
fi

# Display the formatted header
echo -e "${BLUE}$(center_text '╔═══════════════════════════════════════════╗')"
center_text "AlvandNetwork"
center_text "Convert Ubuntu OS to MikroTik CHR"
echo -e "$(center_text '╚═══════════════════════════════════════════╝')${END}"

# Display the OS version
center_text "Your OS version: $OS_VERSION"

sleep 1

# Select chr version
echo ""
echo -e "${YELLOW}Please select your MikroTik version from the section below:${END}"
echo ""
echo "  1) CHR-7.14.3"
echo "  2) CHR-7.9"
echo "  3) CHR-7.7" 
echo ""
echo -ne "${YELLOW}"
read -p "Please enter the CHR version number you want: " chr_id
echo -ne "${END}"

case $chr_id in
    1) v="7.14.3";;
    2) v="7.9";;
    3) v="7.7";;
    *) echo -e "${RED}Invalid ID. The script is closed...${END}"; exit 1;;
esac
echo -e ""
echo -e "${BLUE}Received, You have selected version (${v}) ${END}"
echo -e ""
echo -e "${BLUE}$(center_text '═════════════════════════════════════════════')${END}"
# ========================================
echo -e ""
echo -e "${YELLOW}Step 1, install the required packages...${END}"

sudo apt-get update > /dev/null &
PID=$!
while ps | grep -q $PID; do
    sleep 1
done

sudo apt-get install -y kpartx > /dev/null &
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install the required packages. The script is closed.${END}"
    exit 1
fi
PID=$!
while ps | grep -q $PID; do
    sleep 1
done

echo -e ""
echo -e "${GREEN}  The required packages were successfully installed.${END}"
# ========================================
echo -e ""
echo -e "${YELLOW}Step 2, Downloading MikroTik installation file...${END}"

wget https://dl.alvandnetwork.com/routeros/chr-${v}.img.zip -O chr.img.zip > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download MikroTik installation file. The script is closed.${END}"
    exit 1
fi

echo -e ""
echo -e "${GREEN}MikroTik installation file has been downloaded successfully.${END}"
# ========================================
echo -e ""
echo -e "${YELLOW}Step 3, Extracting the MikroTik installation file...${END}"

gunzip -c chr.img.zip > chr.img
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to extract MikroTik installation file. The script is closed.${END}"
    exit 1
fi

echo -e ""
echo -e "${GREEN}MikroTik installation file extracted successfully.${END}"
# ========================================
echo -e ""
echo -e "${YELLOW}Step 4, Setting up loop device and partitions...${END}"

LP=$(sudo losetup -f --show chr.img)
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to set up loop device. The script is closed.${END}"
    exit 1
fi

sudo kpartx -a $LP > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to set up partitions. The script is closed.${END}"
    exit 1
fi

echo -e ""
echo -e "${GREEN}Loop device set up at ${LP}.${END}"
# ========================================
echo -e ""
echo -e "${YELLOW}Step 5, Installing MikroTik file...${END}"

sudo mount /dev/mapper/$(basename ${LP})p1 /mnt > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}MikroTik installation failed. The script is closed.${END}"
    exit 1
fi

echo -e ""
echo -e "${GREEN}MikroTik has been successfully installed.${END}"
# ========================================
echo -e ""
echo -e "${YELLOW}Step 6, Network card configuration...${END}"

interface=$(ip route | grep default | awk '{print $5}')
address=$(ip addr show $interface | grep global | cut -d' ' -f 6 | head -n 1)
gateway=$(ip route list | grep default | cut -d' ' -f 3)
if [ -z "$address" ] || [ -z "$gateway" ]; then
    echo -e "${RED}Network card configuration failed. The script is closed.${END}"
    exit 1
fi

echo -e ""
echo -e "${GREEN}Network card configuration is done. IPv4: $address${END}"
# ========================================
echo -e ""
echo -e "${YELLOW}Step 7, Identify system storage...${END}"

storage=$(fdisk -l | grep "^Disk /dev" | grep -v "^Disk /dev/loop" | cut -d' ' -f2 | tr -d ':')
if [ -z "$storage" ]; then
    echo -e "${RED}Storage not found, The script is closed.${END}"
    exit 1
fi

echo -e ""
echo -e "${GREEN}Successfully, Using storage: $storage${END}"
# ========================================
echo -e ""
echo -e "${YELLOW}Step 8, Syncing storage...${END}"

echo u | sudo tee /proc/sysrq-trigger > /dev/null 2>&1
sudo dd if=chr.img bs=1024 of=$storage

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to prepare disk for installation. Exiting.${END}"
    exit 1
fi

sudo sync

echo -e ""
echo -e "${GREEN}Storage sync was successful.${END}"
# ========================================
echo -e ""
echo -e "${BLUE}$(center_text '╔═══════════════════════════════════════════╗')"
center_text "MikroTik installation is done successfully."
center_text "AlvandNetwork"
echo -e "$(center_text '╚═══════════════════════════════════════════╝')${END}"
echo -e ""
# ========================================
rm -f chr.img.zip > /dev/null 2>&1
sudo umount /mnt > /dev/null 2>&1
sudo losetup -d $LP
echo -e "${GREEN}System reboot to boot MikroTik...${END}"
echo b | sudo tee /proc/sysrq-trigger > /dev/null 2>&1
# ========================================
# END
# AlvandNetwork.com
