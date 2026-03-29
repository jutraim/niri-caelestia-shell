#!/bin/bash

# Configuration
SHELL_DIR="$HOME/.config/quickshell/niri-caelestia-shell"
REPO_URL="https://github.com/jutraim/niri-caelestia-shell"
LOG_FILE="$HOME/caelestia_update.log"

# Function to show progress
show_progress() {
    local message=$1
    local percent=$2
    echo -ne "  [Updating] $percent% : $message\r"
}

# Custom Logo
clear
echo -e "\e[1;34m"
echo "             ____  ____  ___  ____________"
echo "      __  __/ __ \/ __ \/   |/_  __/ ____/"
echo "     / / / / /_/ / / / / /| | / / / __/   "
echo "    / /_/ / ____/ /_/ / ___ |/ / / /___  "
echo "    \__,_/_/   /_____/_/  |_/_/ /_____/  "
echo -e "\e[0m"

echo "Initializing Clean Update Engine..."
echo "Logs are being saved to: $LOG_FILE"
echo "----------------------------------------------------------"

# 1. Directory & Git Setup
show_progress "Configuring Repository" 10
if [ ! -d "$SHELL_DIR" ]; then
    mkdir -p "$SHELL_DIR"
fi
cd "$SHELL_DIR" || exit
if [ ! -d ".git" ]; then
    git init &>> "$LOG_FILE"
    git remote add origin "$REPO_URL" &>> "$LOG_FILE"
else
    git remote set-url origin "$REPO_URL" &>> "$LOG_FILE"
fi

# 2. Pulling Updates
show_progress "Fetching latest changes" 25
git fetch origin &>> "$LOG_FILE"
git checkout -f main &>> "$LOG_FILE"
git pull origin main &>> "$LOG_FILE"
git tag 1.1.1 2>/dev/null

# 3. Cleaning & Patching
show_progress "Applying Cava-Removal patches" 45
rm -rf build &>> "$LOG_FILE"
sed -i '/cavaprovider/d' plugin/src/Caelestia/CMakeLists.txt
sed -i '/PkgConfig::cava/d' plugin/src/Caelestia/CMakeLists.txt

# QML Patching
if [ -f "services/Cava.qml" ]; then
    echo -e "import QtQuick\n\nQtObject {\n    // Cava Disabled by Sarok\n}" > services/Cava.qml
fi
if [ -f "services/BeatDetector.qml" ]; then
    echo -e "import QtQuick\n\nQtObject {\n    // BeatDetector Disabled by Sarok\n}" > services/BeatDetector.qml
fi

# 4. Building (The heavy part)
show_progress "Compiling C++ Plugin (Please wait)" 70
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release &>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    cmake --build build &>> "$LOG_FILE"
    
    # 5. Installing
    show_progress "Installing to system" 90
    sudo cmake --install build &>> "$LOG_FILE"
    
    echo -ne "\n\n"
    echo "SUCCESS: Update completed successfully."
    echo "----------------------------------------------------------"
    
    # Restart Prompt
    read -p "Restart shell now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        killall quickshell 2>/dev/null
        qs -c niri-caelestia-shell &> /dev/null &
        echo "Shell restarted in background."
    fi
else
    echo -e "\n\nERROR: Build failed. Check $LOG_FILE for details."
fi