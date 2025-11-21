#!/bin/bash
# Automated setup script for reminders-api with Caddy
# Run this on aurelius (the Mac running the services)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================"
echo "Setting up reminders-api with Caddy"
echo "================================================"
echo ""

# Get username
USER=$(whoami)
USER_HOME="$HOME"

echo "Setting up for user: $USER"
echo "Home directory: $USER_HOME"
echo ""

# Ask for configuration
echo -e "${BLUE}Configuration Questions:${NC}"
echo ""

read -p "Auth token for reminders-api (leave blank for no auth): " AUTH_TOKEN
echo ""

read -p "Port for Caddy to listen on (default 8080): " CADDY_PORT
CADDY_PORT=${CADDY_PORT:-8080}
echo ""

echo -e "${YELLOW}Choose exposure method:${NC}"
echo "1) Local only (Tailscale Serve - recommended)"
echo "2) Public (Tailscale Funnel)"
echo "3) Manual (I'll configure it myself)"
read -p "Choice (1-3): " EXPOSURE_CHOICE
echo ""

# Create directory structure
SERVICES_DIR="$USER_HOME/reminders-services"
echo "Creating directory structure at $SERVICES_DIR..."
mkdir -p "$SERVICES_DIR"
cd "$SERVICES_DIR"

# Find reminders-api binary
echo "Looking for reminders-api binary..."
REMINDERS_API_PATH=$(which reminders-api 2>/dev/null || echo "")
if [ -z "$REMINDERS_API_PATH" ]; then
    echo -e "${RED}Error: reminders-api not found in PATH${NC}"
    echo "Please install reminders-cli first:"
    echo "  https://github.com/cromulus/reminders-cli"
    exit 1
fi
echo -e "${GREEN}Found: $REMINDERS_API_PATH${NC}"
echo ""

# Check for Caddy
if ! command -v caddy &> /dev/null; then
    echo -e "${YELLOW}Caddy not found. Installing via Homebrew...${NC}"
    brew install caddy
fi
echo -e "${GREEN}Caddy installed${NC}"
echo ""

# Create Caddyfile
echo "Creating Caddyfile..."
cat > "$SERVICES_DIR/Caddyfile" << 'CADDYFILE_END'
:8080 {
    # Health check
    handle /health {
        respond "OK" 200
    }

    # reminders-api endpoints
    handle /lists* {
        reverse_proxy localhost:8081
    }

    handle /reminders* {
        reverse_proxy localhost:8081
    }

    handle /webhooks* {
        reverse_proxy localhost:8081
    }

    # Catch-all
    handle {
        reverse_proxy localhost:8081
    }

    # Logging
    log {
        output file /Users/USER_HOME/reminders-services/access.log
    }
}
CADDYFILE_END

# Replace placeholders
sed -i '' "s|:8080|:$CADDY_PORT|g" "$SERVICES_DIR/Caddyfile"
sed -i '' "s|USER_HOME|$USER|g" "$SERVICES_DIR/Caddyfile"
echo -e "${GREEN}Caddyfile created${NC}"
echo ""

# Create run script for reminders-api
echo "Creating reminders-api run script..."
cat > "$SERVICES_DIR/run-reminders-api.sh" << RUNSCRIPT_END
#!/bin/bash
cd "$SERVICES_DIR"

# Run reminders-api
if [ -n "$AUTH_TOKEN" ]; then
    exec reminders-api --auth-required --token "$AUTH_TOKEN" --host 127.0.0.1 --port 8081
else
    exec reminders-api --host 127.0.0.1 --port 8081
fi
RUNSCRIPT_END

chmod +x "$SERVICES_DIR/run-reminders-api.sh"
echo -e "${GREEN}reminders-api run script created${NC}"
echo ""

# Create run script for Caddy
echo "Creating Caddy run script..."
cat > "$SERVICES_DIR/run-caddy.sh" << 'RUNSCRIPT_END'
#!/bin/bash
cd SERVICES_DIR
exec caddy run --config Caddyfile
RUNSCRIPT_END

sed -i '' "s|SERVICES_DIR|$SERVICES_DIR|g" "$SERVICES_DIR/run-caddy.sh"
chmod +x "$SERVICES_DIR/run-caddy.sh"
echo -e "${GREEN}Caddy run script created${NC}"
echo ""

# Create LaunchAgent for reminders-api
echo "Creating LaunchAgent for reminders-api..."
cat > "$USER_HOME/Library/LaunchAgents/com.reminders-api.plist" << PLIST_END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.reminders-api</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SERVICES_DIR/run-reminders-api.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$SERVICES_DIR/reminders-api.log</string>
    <key>StandardErrorPath</key>
    <string>$SERVICES_DIR/reminders-api.error.log</string>
    <key>WorkingDirectory</key>
    <string>$SERVICES_DIR</string>
</dict>
</plist>
PLIST_END

echo -e "${GREEN}reminders-api LaunchAgent created${NC}"
echo ""

# Create LaunchAgent for Caddy
echo "Creating LaunchAgent for Caddy..."
cat > "$USER_HOME/Library/LaunchAgents/com.caddy.plist" << PLIST_END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.caddy</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SERVICES_DIR/run-caddy.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$SERVICES_DIR/caddy.log</string>
    <key>StandardErrorPath</key>
    <string>$SERVICES_DIR/caddy.error.log</string>
    <key>WorkingDirectory</key>
    <string>$SERVICES_DIR</string>
</dict>
</plist>
PLIST_END

echo -e "${GREEN}Caddy LaunchAgent created${NC}"
echo ""

# Load services
echo "Loading services..."
launchctl load "$USER_HOME/Library/LaunchAgents/com.reminders-api.plist"
launchctl load "$USER_HOME/Library/LaunchAgents/com.caddy.plist"
echo -e "${GREEN}Services loaded${NC}"
echo ""

# Wait a moment for services to start
echo "Waiting for services to start..."
sleep 3

# Test
echo "Testing services..."
if curl -s http://localhost:8081/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ reminders-api is running${NC}"
else
    echo -e "${RED}✗ reminders-api is not responding${NC}"
    echo "Check logs: tail -f $SERVICES_DIR/reminders-api.error.log"
fi

if curl -s http://localhost:$CADDY_PORT/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Caddy is running${NC}"
else
    echo -e "${RED}✗ Caddy is not responding${NC}"
    echo "Check logs: tail -f $SERVICES_DIR/caddy.error.log"
fi

# Test through Caddy
echo ""
echo "Testing API through Caddy..."
if curl -s http://localhost:$CADDY_PORT/lists > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Can reach API through Caddy${NC}"
    echo ""
    echo "Response from /lists:"
    curl -s http://localhost:$CADDY_PORT/lists | jq . 2>/dev/null || curl -s http://localhost:$CADDY_PORT/lists
else
    echo -e "${RED}✗ Cannot reach API through Caddy${NC}"
fi

# Setup Tailscale
echo ""
echo "================================================"
case $EXPOSURE_CHOICE in
    1)
        echo -e "${BLUE}Setting up Tailscale Serve (private)...${NC}"
        echo "Run this command:"
        echo "  tailscale serve https / http://127.0.0.1:$CADDY_PORT"
        ;;
    2)
        echo -e "${BLUE}Setting up Tailscale Funnel (public)...${NC}"
        echo "Run this command:"
        echo "  tailscale funnel $CADDY_PORT"
        ;;
    3)
        echo -e "${BLUE}Manual configuration${NC}"
        echo "Configure your preferred exposure method"
        ;;
esac

echo ""
echo "================================================"
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Services are running at:"
echo "  reminders-api: http://localhost:8081"
echo "  Caddy:         http://localhost:$CADDY_PORT"
echo ""
echo "Files created:"
echo "  $SERVICES_DIR/Caddyfile"
echo "  $SERVICES_DIR/run-reminders-api.sh"
echo "  $SERVICES_DIR/run-caddy.sh"
echo "  ~/Library/LaunchAgents/com.reminders-api.plist"
echo "  ~/Library/LaunchAgents/com.caddy.plist"
echo ""
echo "Logs:"
echo "  tail -f $SERVICES_DIR/reminders-api.log"
echo "  tail -f $SERVICES_DIR/caddy.log"
echo ""
echo "Manage services:"
echo "  launchctl list | grep com.reminders-api"
echo "  launchctl list | grep com.caddy"
echo ""
echo "  launchctl unload ~/Library/LaunchAgents/com.reminders-api.plist"
echo "  launchctl load ~/Library/LaunchAgents/com.reminders-api.plist"
echo "================================================"
