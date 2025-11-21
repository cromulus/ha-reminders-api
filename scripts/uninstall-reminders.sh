#!/bin/bash
# Script to uninstall reminders-api components

echo "================================================"
echo "Uninstalling reminders-api"
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Require confirmation
echo -e "${YELLOW}WARNING: This will remove reminders-api components${NC}"
echo "This script will:"
echo "  - Stop running processes"
echo "  - Unload launchd services"
echo "  - Remove plist files"
echo "  - Remove binaries"
echo "  - Remove config and log files"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 1
fi

echo ""
echo "1. Stopping running processes..."
pkill -f "reminders-api" && echo -e "${GREEN}  Stopped reminders-api${NC}" || echo "  No running reminders-api"
pkill -f "reminders-cli" && echo -e "${GREEN}  Stopped reminders-cli${NC}" || echo "  No running reminders-cli"

echo ""
echo "2. Unloading LaunchDaemons..."
for file in /Library/LaunchDaemons/*reminders* /Library/LaunchDaemons/*reminders-api* /Library/LaunchDaemons/*reminders-cli*; do
    if [ -f "$file" ]; then
        echo "  Unloading $file"
        sudo launchctl unload "$file" 2>/dev/null
        sudo rm "$file" && echo -e "${GREEN}    Removed${NC}"
    fi
done

echo ""
echo "3. Unloading LaunchAgents..."
for file in ~/Library/LaunchAgents/*reminders* ~/Library/LaunchAgents/*reminders-api* ~/Library/LaunchAgents/*reminders-cli*; do
    if [ -f "$file" ]; then
        echo "  Unloading $file"
        launchctl unload "$file" 2>/dev/null
        rm "$file" && echo -e "${GREEN}    Removed${NC}"
    fi
done

echo ""
echo "4. Removing binaries..."
for path in /usr/local/bin /opt/homebrew/bin /opt/local/bin ~/.local/bin; do
    for bin in reminders-api reminders-cli; do
        if [ -f "$path/$bin" ]; then
            echo "  Removing $path/$bin"
            sudo rm "$path/$bin" 2>/dev/null || rm "$path/$bin"
            echo -e "${GREEN}    Removed${NC}"
        fi
    done
done

echo ""
echo "5. Removing config directories..."
for dir in ~/.config/reminders* ~/.reminders* /etc/reminders* /usr/local/etc/reminders*; do
    if [ -d "$dir" ]; then
        echo "  Removing $dir"
        sudo rm -rf "$dir" 2>/dev/null || rm -rf "$dir"
        echo -e "${GREEN}    Removed${NC}"
    fi
done

echo ""
echo "6. Removing log files..."
for log in /var/log/*reminders* /tmp/*reminders* ~/Library/Logs/*reminders*; do
    if [ -f "$log" ]; then
        echo "  Removing $log"
        sudo rm "$log" 2>/dev/null || rm "$log"
        echo -e "${GREEN}    Removed${NC}"
    fi
done

echo ""
echo "7. Checking Homebrew installations..."
if command -v brew &> /dev/null; then
    if brew list 2>/dev/null | grep -i reminders > /dev/null; then
        echo -e "${YELLOW}  Found Homebrew packages:${NC}"
        brew list | grep -i reminders
        echo ""
        read -p "  Uninstall Homebrew packages? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for pkg in $(brew list | grep -i reminders); do
                brew uninstall "$pkg" && echo -e "${GREEN}    Uninstalled $pkg${NC}"
            done
        fi
    fi
fi

echo ""
echo "================================================"
echo -e "${GREEN}Uninstall complete!${NC}"
echo ""
echo "Note: Git repositories were NOT removed."
echo "If you want to remove source code, manually delete directories like:"
echo "  ~/reminders-cli"
echo "  ~/code/reminders-cli"
echo "  etc."
echo "================================================"
