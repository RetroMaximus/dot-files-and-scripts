#!/bin/bash

echo "Checking tmux installation and functionality..."

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "tmux is not installed. Installing tmux..."
    pacman -S --noconfirm tmux
else
    echo "tmux is already installed."
fi

# Verify tmux binary path
TMUX_PATH=$(which tmux)
echo "tmux binary path: $TMUX_PATH"

# Verify tmux version
echo "Checking tmux version..."
tmux -V
if [ $? -ne 0 ]; then
    echo "Warning - Error while checking version"
    echo "What would you like to do?"
    echo "0. Backup MSYS Configuration and Data"
    echo "1. No, just Continue"
    echo "2. Check Missing DLL's"
    echo "3. Reinstall MSYS Components"
    echo "4. Abort"
    read -p "Choose an option (0-4): " CHOICE

    case $CHOICE in
        0)
            echo "Backing up MSYS configuration and data..."
            tar -cvzf msys2_backup.tar.gz /path/to/msys2
            ;;
        1)
            echo "Continuing without any changes..."
            ;;
        2)
            echo "Checking for missing or corrupted DLLs..."
            for dll in \
                /c/Windows/SYSTEM32/ntdll.dll \
                /c/Windows/System32/KERNEL32.DLL \
                /c/Windows/System32/KERNELBASE.dll \
                /usr/bin/msys-event_core-2-1-7.dll \
                /usr/bin/msys-2.0.dll \
                /usr/bin/msys-ncursesw6.dll; do
                if [ -f "$dll" ]; then
                    echo "$dll found."
                else
                    echo "$dll missing or corrupted."
                fi
            done
            ;;
        3)
            echo "Reinstalling MSYS2 components..."
            pacman -Syu
            pacman -S --noconfirm msys2-runtime
            pacman -S --noconfirm mingw-w64-x86_64-toolchain base-devel
            ;;
        4)
            echo "Aborting..."
            exit 1
            ;;
        *)
            echo "Invalid option. Aborting..."
            exit 1
            ;;
    esac
fi

# Check tmux dependencies
echo "Checking tmux dependencies..."
ldd $TMUX_PATH

# Run tmux in verbose mode and log output
echo "Running tmux in verbose mode..."
tmux -vv new-session
if [ $? -ne 0 ]; then
    echo "Failed to start a new tmux session."
    echo "Checking for tmux logs in /tmp..."
    ls /tmp/tmux-server-*.log 2>/dev/null && cat /tmp/tmux-server-*.log || echo "No tmux logs found."

    # Reinstall tmux if necessary
    read -p "Would you like to reinstall tmux? (y/n): " REINSTALL
    if [ "$REINSTALL" == "y" ]; then
    echo "Reinstalling tmux..."
    pacman -R --noconfirm tmux
    pacman -S --noconfirm tmux
    echo "Reinstalled tmux."
    echo "Checking tmux version..."
    tmux -V || echo "Failed to get tmux version."
fi

else
    echo "tmux session started and exited successfully."
fi

echo "Script completed."
