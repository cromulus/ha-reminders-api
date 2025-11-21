#!/bin/bash
# Script to discover what the reminders-api install script created

echo "================================================"
echo "Discovering reminders-api Installation"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

found_something=false

echo "1. Checking for LaunchDaemons (system-level, runs as root)..."
for file in /Library/LaunchDaemons/*reminders* /Library/LaunchDaemons/*reminders-api* /Library/LaunchDaemons/*reminders-cli*; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  FOUND:${NC} $file"
        found_something=true
    fi
done

echo ""
echo "2. Checking for LaunchAgents (user-level, runs as your user)..."
for file in ~/Library/LaunchAgents/*reminders* ~/Library/LaunchAgents/*reminders-api* ~/Library/LaunchAgents/*reminders-cli*; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  FOUND:${NC} $file"
        found_something=true
    fi
done

echo ""
echo "3. Checking for binaries in common locations..."
for path in /usr/local/bin /opt/homebrew/bin /opt/local/bin ~/.local/bin /usr/bin; do
    for bin in reminders-api reminders-cli reminders; do
        if [ -f "$path/$bin" ]; then
            echo -e "${GREEN}  FOUND:${NC} $path/$bin"
            ls -lh "$path/$bin"
            found_something=true
        fi
    done
done

echo ""
echo "4. Checking for running processes..."
if pgrep -fl "reminders" > /dev/null; then
    echo -e "${GREEN}  FOUND running processes:${NC}"
    pgrep -fl "reminders"
    found_something=true
else
    echo "  No running reminders processes"
fi

echo ""
echo "5. Checking for config directories..."
for dir in ~/.config/reminders* ~/.reminders* /etc/reminders* /usr/local/etc/reminders*; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}  FOUND:${NC} $dir"
        ls -la "$dir"
        found_something=true
    fi
done

echo ""
echo "6. Checking for log files..."
for log in /var/log/*reminders* /tmp/*reminders* ~/Library/Logs/*reminders*; do
    if [ -f "$log" ]; then
        echo -e "${GREEN}  FOUND:${NC} $log"
        found_something=true
    fi
done

echo ""
echo "7. Checking loaded launchd services..."
if launchctl list | grep -i reminders > /dev/null; then
    echo -e "${GREEN}  FOUND loaded services:${NC}"
    launchctl list | grep -i reminders
    found_something=true
else
    echo "  No loaded launchd services with 'reminders' in name"
fi

echo ""
echo "8. Checking Homebrew installations..."
if command -v brew &> /dev/null; then
    if brew list 2>/dev/null | grep -i reminders > /dev/null; then
        echo -e "${GREEN}  FOUND Homebrew packages:${NC}"
        brew list | grep -i reminders
        brew info $(brew list | grep -i reminders) 2>/dev/null
        found_something=true
    else
        echo "  No Homebrew packages found"
    fi
else
    echo "  Homebrew not installed"
fi

echo ""
echo "9. Checking for GitHub clones..."
for dir in ~/reminders* ~/src/reminders* ~/code/reminders* ~/git/reminders* ~/Developer/reminders* ~/Documents/reminders*; do
    if [ -d "$dir/.git" ]; then
        echo -e "${GREEN}  FOUND git repository:${NC} $dir"
        cd "$dir" && git remote -v 2>/dev/null | head -1
        found_something=true
    fi
done

echo ""
echo "================================================"
if [ "$found_something" = true ]; then
    echo -e "${YELLOW}Summary: Found reminders-api installation components${NC}"
    echo "Review the output above to see what was installed."
    echo ""
    echo "Run ./uninstall-reminders.sh to remove these components"
else
    echo "No reminders-api installation found"
fi
echo "================================================"
