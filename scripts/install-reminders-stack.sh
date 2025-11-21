#!/bin/bash
# Complete install script for reminders-api + MCP with Caddy + Cloudflare Tunnel
# This should be contributed to cromulus/reminders-cli repository

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Reminders Stack Installer (API + MCP + Caddy + Tunnel)    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script requires macOS${NC}"
    exit 1
fi

USER=$(whoami)
USER_HOME="$HOME"

# ============================================================================
# STEP 1: Configuration Questions
# ============================================================================

echo -e "${CYAN}═══ Step 1: Configuration ═══${NC}"
echo ""

echo "Service Configuration:"
read -p "  Enable authentication? (Y/n): " ENABLE_AUTH
ENABLE_AUTH=${ENABLE_AUTH:-Y}

if [[ "$ENABLE_AUTH" =~ ^[Yy]$ ]]; then
    read -p "  Auth token (leave blank to auto-generate): " AUTH_TOKEN
    if [ -z "$AUTH_TOKEN" ]; then
        AUTH_TOKEN=$(openssl rand -hex 32)
        echo -e "  ${GREEN}Generated token: $AUTH_TOKEN${NC}"
    fi
else
    AUTH_TOKEN=""
fi
echo ""

echo "Exposure Method:"
echo "  1) Cloudflare Tunnel (recommended - reliable, free, custom domain)"
echo "  2) Tailscale Funnel (easy - uses tailscale hostname)"
echo "  3) Tailscale Serve (private - only your tailnet)"
echo "  4) Local only (no remote access)"
read -p "  Choice (1-4): " EXPOSURE_METHOD
echo ""

if [ "$EXPOSURE_METHOD" = "1" ]; then
    echo "Cloudflare Configuration:"
    read -p "  Domain (e.g., reminders.yourdomain.com): " CF_DOMAIN
    read -p "  Cloudflare API Token: " CF_API_TOKEN
    read -p "  Cloudflare Account ID: " CF_ACCOUNT_ID
    read -p "  Cloudflare Zone ID: " CF_ZONE_ID
    echo ""
fi

echo "Ports Configuration:"
read -p "  Caddy external port (default 443): " CADDY_PORT
CADDY_PORT=${CADDY_PORT:-443}
REMINDERS_API_PORT=8081
MCP_PORT=8082
echo ""

echo "Optional Services:"
read -p "  Install MCP server? (Y/n): " INSTALL_MCP
INSTALL_MCP=${INSTALL_MCP:-Y}
echo ""

# ============================================================================
# STEP 2: Install Dependencies
# ============================================================================

echo -e "${CYAN}═══ Step 2: Installing Dependencies ═══${NC}"
echo ""

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Caddy
if ! command -v caddy &> /dev/null; then
    echo "Installing Caddy..."
    brew install caddy
    echo -e "${GREEN}✓ Caddy installed${NC}"
else
    echo -e "${GREEN}✓ Caddy already installed${NC}"
fi

# Install Cloudflare CLI if needed
if [ "$EXPOSURE_METHOD" = "1" ]; then
    if ! command -v cloudflared &> /dev/null; then
        echo "Installing cloudflared..."
        brew install cloudflare/cloudflare/cloudflared
        echo -e "${GREEN}✓ cloudflared installed${NC}"
    else
        echo -e "${GREEN}✓ cloudflared already installed${NC}"
    fi
fi

echo ""

# ============================================================================
# STEP 3: Install reminders-api
# ============================================================================

echo -e "${CYAN}═══ Step 3: Installing reminders-api ═══${NC}"
echo ""

# Check if reminders-api exists
if ! command -v reminders-api &> /dev/null; then
    echo "reminders-api not found. Please install it first:"
    echo "  https://github.com/cromulus/reminders-cli"
    exit 1
fi

# Find the binary
REMINDERS_API_PATH=$(which reminders-api)
echo -e "Found reminders-api at: ${GREEN}$REMINDERS_API_PATH${NC}"

# Link to standard location if not there
if [ "$REMINDERS_API_PATH" != "/usr/local/bin/reminders-api" ]; then
    echo "Creating symlink in /usr/local/bin..."
    sudo ln -sf "$REMINDERS_API_PATH" /usr/local/bin/reminders-api
fi

echo ""

# ============================================================================
# STEP 4: Create Service Directory Structure
# ============================================================================

echo -e "${CYAN}═══ Step 4: Creating Service Structure ═══${NC}"
echo ""

SERVICES_DIR="$USER_HOME/reminders-stack"
mkdir -p "$SERVICES_DIR"
mkdir -p "$SERVICES_DIR/logs"
mkdir -p "$SERVICES_DIR/config"

echo -e "Created: ${GREEN}$SERVICES_DIR${NC}"
echo ""

# ============================================================================
# STEP 5: Create Caddyfile
# ============================================================================

echo -e "${CYAN}═══ Step 5: Configuring Caddy ═══${NC}"
echo ""

cat > "$SERVICES_DIR/Caddyfile" << 'CADDYFILE_END'
# Caddy configuration for reminders stack

:CADDY_PORT {
    # Health check endpoint
    handle /health {
        respond "OK" 200
    }

    # reminders-api at /api/*
    handle_path /api/* {
        reverse_proxy localhost:REMINDERS_API_PORT {
            header_up X-Forwarded-Prefix /api
        }
    }

    # MCP server at /mcp/*
    handle_path /mcp/* {
        reverse_proxy localhost:MCP_PORT {
            header_up X-Forwarded-Prefix /mcp
        }
    }

    # Root redirects to health
    handle / {
        redir /health
    }

    # Authentication (if enabled)
    @authenticated {
        header Authorization "Bearer AUTH_TOKEN"
    }

    # Logging
    log {
        output file SERVICES_DIR/logs/access.log {
            roll_size 10MB
            roll_keep 5
        }
    }
}
CADDYFILE_END

# Replace placeholders
sed -i '' "s|:CADDY_PORT|:$CADDY_PORT|g" "$SERVICES_DIR/Caddyfile"
sed -i '' "s|REMINDERS_API_PORT|$REMINDERS_API_PORT|g" "$SERVICES_DIR/Caddyfile"
sed -i '' "s|MCP_PORT|$MCP_PORT|g" "$SERVICES_DIR/Caddyfile"
sed -i '' "s|AUTH_TOKEN|$AUTH_TOKEN|g" "$SERVICES_DIR/Caddyfile"
sed -i '' "s|SERVICES_DIR|$SERVICES_DIR|g" "$SERVICES_DIR/Caddyfile"

echo -e "${GREEN}✓ Caddyfile created${NC}"
echo ""

# ============================================================================
# STEP 6: Create Service Scripts
# ============================================================================

echo -e "${CYAN}═══ Step 6: Creating Service Scripts ═══${NC}"
echo ""

# reminders-api script
cat > "$SERVICES_DIR/run-reminders-api.sh" << SCRIPT_END
#!/bin/bash
cd "$SERVICES_DIR"

if [ -n "$AUTH_TOKEN" ]; then
    exec reminders-api \\
        --auth-required \\
        --token "$AUTH_TOKEN" \\
        --host 127.0.0.1 \\
        --port $REMINDERS_API_PORT
else
    exec reminders-api \\
        --host 127.0.0.1 \\
        --port $REMINDERS_API_PORT
fi
SCRIPT_END

chmod +x "$SERVICES_DIR/run-reminders-api.sh"
echo -e "${GREEN}✓ reminders-api script created${NC}"

# MCP script (if requested)
if [[ "$INSTALL_MCP" =~ ^[Yy]$ ]]; then
    cat > "$SERVICES_DIR/run-mcp.sh" << 'SCRIPT_END'
#!/bin/bash
cd "$SERVICES_DIR"

# TODO: Replace with actual MCP server command
# exec your-mcp-server --host 127.0.0.1 --port MCP_PORT

echo "MCP server not configured. Edit this script to add your MCP server."
sleep infinity
SCRIPT_END

    sed -i '' "s|MCP_PORT|$MCP_PORT|g" "$SERVICES_DIR/run-mcp.sh"
    chmod +x "$SERVICES_DIR/run-mcp.sh"
    echo -e "${GREEN}✓ MCP script created (needs configuration)${NC}"
fi

# Caddy script
cat > "$SERVICES_DIR/run-caddy.sh" << SCRIPT_END
#!/bin/bash
cd "$SERVICES_DIR"
exec caddy run --config Caddyfile
SCRIPT_END

chmod +x "$SERVICES_DIR/run-caddy.sh"
echo -e "${GREEN}✓ Caddy script created${NC}"

echo ""

# ============================================================================
# STEP 7: Create LaunchAgents
# ============================================================================

echo -e "${CYAN}═══ Step 7: Creating LaunchAgents ═══${NC}"
echo ""

# reminders-api LaunchAgent
cat > "$USER_HOME/Library/LaunchAgents/com.reminders.api.plist" << PLIST_END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.reminders.api</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SERVICES_DIR/run-reminders-api.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$SERVICES_DIR/logs/reminders-api.log</string>
    <key>StandardErrorPath</key>
    <string>$SERVICES_DIR/logs/reminders-api.error.log</string>
    <key>WorkingDirectory</key>
    <string>$SERVICES_DIR</string>
</dict>
</plist>
PLIST_END

echo -e "${GREEN}✓ reminders-api LaunchAgent created${NC}"

# MCP LaunchAgent (if requested)
if [[ "$INSTALL_MCP" =~ ^[Yy]$ ]]; then
    cat > "$USER_HOME/Library/LaunchAgents/com.reminders.mcp.plist" << PLIST_END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.reminders.mcp</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SERVICES_DIR/run-mcp.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$SERVICES_DIR/logs/mcp.log</string>
    <key>StandardErrorPath</key>
    <string>$SERVICES_DIR/logs/mcp.error.log</string>
    <key>WorkingDirectory</key>
    <string>$SERVICES_DIR</string>
</dict>
</plist>
PLIST_END

    echo -e "${GREEN}✓ MCP LaunchAgent created${NC}"
fi

# Caddy LaunchAgent
cat > "$USER_HOME/Library/LaunchAgents/com.reminders.caddy.plist" << PLIST_END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.reminders.caddy</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SERVICES_DIR/run-caddy.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$SERVICES_DIR/logs/caddy.log</string>
    <key>StandardErrorPath</key>
    <string>$SERVICES_DIR/logs/caddy.error.log</string>
    <key>WorkingDirectory</key>
    <string>$SERVICES_DIR</string>
</dict>
</plist>
PLIST_END

echo -e "${GREEN}✓ Caddy LaunchAgent created${NC}"
echo ""

# ============================================================================
# STEP 8: Configure Cloudflare Tunnel (if selected)
# ============================================================================

if [ "$EXPOSURE_METHOD" = "1" ]; then
    echo -e "${CYAN}═══ Step 8: Configuring Cloudflare Tunnel ═══${NC}"
    echo ""

    # Authenticate
    echo "Authenticating with Cloudflare..."
    export CLOUDFLARE_API_TOKEN="$CF_API_TOKEN"
    cloudflared tunnel login --api-token "$CF_API_TOKEN" 2>/dev/null || true

    # Create tunnel
    TUNNEL_NAME="reminders-$(date +%s)"
    echo "Creating tunnel: $TUNNEL_NAME"
    cloudflared tunnel create "$TUNNEL_NAME"

    # Get tunnel ID
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    echo -e "Tunnel ID: ${GREEN}$TUNNEL_ID${NC}"

    # Create tunnel config
    mkdir -p "$USER_HOME/.cloudflared"
    cat > "$USER_HOME/.cloudflared/config.yml" << CF_CONFIG_END
tunnel: $TUNNEL_ID
credentials-file: $USER_HOME/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $CF_DOMAIN
    service: http://localhost:$CADDY_PORT
  - service: http_status:404
CF_CONFIG_END

    # Create DNS record
    echo "Creating DNS record..."
    cloudflared tunnel route dns "$TUNNEL_ID" "$CF_DOMAIN"

    # Create LaunchAgent for tunnel
    cat > "$USER_HOME/Library/LaunchAgents/com.reminders.cloudflared.plist" << PLIST_END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.reminders.cloudflared</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/cloudflared</string>
        <string>tunnel</string>
        <string>run</string>
        <string>$TUNNEL_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$SERVICES_DIR/logs/cloudflared.log</string>
    <key>StandardErrorPath</key>
    <string>$SERVICES_DIR/logs/cloudflared.error.log</string>
    <key>WorkingDirectory</key>
    <string>$USER_HOME/.cloudflared</string>
</dict>
</plist>
PLIST_END

    echo -e "${GREEN}✓ Cloudflare Tunnel configured${NC}"
    echo ""
fi

# ============================================================================
# STEP 9: Load Services
# ============================================================================

echo -e "${CYAN}═══ Step 9: Starting Services ═══${NC}"
echo ""

# Load LaunchAgents
echo "Loading reminders-api..."
launchctl load "$USER_HOME/Library/LaunchAgents/com.reminders.api.plist"
sleep 2

if [[ "$INSTALL_MCP" =~ ^[Yy]$ ]]; then
    echo "Loading MCP server..."
    launchctl load "$USER_HOME/Library/LaunchAgents/com.reminders.mcp.plist" 2>/dev/null || echo "  (MCP needs configuration)"
    sleep 1
fi

echo "Loading Caddy..."
launchctl load "$USER_HOME/Library/LaunchAgents/com.reminders.caddy.plist"
sleep 2

if [ "$EXPOSURE_METHOD" = "1" ]; then
    echo "Loading Cloudflare Tunnel..."
    launchctl load "$USER_HOME/Library/LaunchAgents/com.reminders.cloudflared.plist"
    sleep 2
fi

echo ""

# ============================================================================
# STEP 10: Test Services
# ============================================================================

echo -e "${CYAN}═══ Step 10: Testing Services ═══${NC}"
echo ""

sleep 3  # Give services time to start

# Test reminders-api
if curl -s http://localhost:$REMINDERS_API_PORT/lists > /dev/null 2>&1; then
    echo -e "${GREEN}✓ reminders-api is running${NC}"
else
    echo -e "${RED}✗ reminders-api is not responding${NC}"
    echo "  Check: tail -f $SERVICES_DIR/logs/reminders-api.error.log"
fi

# Test Caddy
if curl -s http://localhost:$CADDY_PORT/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Caddy is running${NC}"
else
    echo -e "${RED}✗ Caddy is not responding${NC}"
    echo "  Check: tail -f $SERVICES_DIR/logs/caddy.error.log"
fi

# Test API through Caddy
if curl -s http://localhost:$CADDY_PORT/api/lists > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Can reach API through Caddy at /api/*${NC}"
else
    echo -e "${YELLOW}⚠ Cannot reach API through Caddy${NC}"
fi

echo ""

# ============================================================================
# STEP 11: Display Configuration Summary
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                     Installation Complete!                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo -e "${CYAN}Service URLs:${NC}"
echo "  reminders-api: http://localhost:$REMINDERS_API_PORT/lists"
echo "  Caddy:         http://localhost:$CADDY_PORT/health"
echo "  API via Caddy: http://localhost:$CADDY_PORT/api/lists"

if [[ "$INSTALL_MCP" =~ ^[Yy]$ ]]; then
    echo "  MCP via Caddy: http://localhost:$CADDY_PORT/mcp/"
fi
echo ""

if [ "$EXPOSURE_METHOD" = "1" ]; then
    echo -e "${CYAN}Public URL:${NC}"
    echo "  https://$CF_DOMAIN/api/lists"
    echo "  https://$CF_DOMAIN/health"
    echo ""
fi

if [ -n "$AUTH_TOKEN" ]; then
    echo -e "${CYAN}Authentication:${NC}"
    echo "  Token: $AUTH_TOKEN"
    echo "  Header: Authorization: Bearer $AUTH_TOKEN"
    echo ""
fi

echo -e "${CYAN}Home Assistant Configuration:${NC}"
if [ "$EXPOSURE_METHOD" = "1" ]; then
    echo "  URL: https://$CF_DOMAIN/api"
else
    echo "  URL: http://localhost:$CADDY_PORT/api"
fi
if [ -n "$AUTH_TOKEN" ]; then
    echo "  Token: $AUTH_TOKEN"
fi
echo ""

echo -e "${CYAN}Files Created:${NC}"
echo "  $SERVICES_DIR/Caddyfile"
echo "  $SERVICES_DIR/run-reminders-api.sh"
if [[ "$INSTALL_MCP" =~ ^[Yy]$ ]]; then
    echo "  $SERVICES_DIR/run-mcp.sh (needs configuration)"
fi
echo "  $SERVICES_DIR/run-caddy.sh"
echo "  ~/Library/LaunchAgents/com.reminders.*.plist"
echo ""

echo -e "${CYAN}Logs:${NC}"
echo "  tail -f $SERVICES_DIR/logs/*.log"
echo ""

echo -e "${CYAN}Manage Services:${NC}"
echo "  launchctl list | grep com.reminders"
echo "  launchctl unload ~/Library/LaunchAgents/com.reminders.*.plist"
echo "  launchctl load ~/Library/LaunchAgents/com.reminders.*.plist"
echo ""

if [ "$EXPOSURE_METHOD" = "2" ]; then
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  Run: tailscale funnel $CADDY_PORT"
    echo ""
elif [ "$EXPOSURE_METHOD" = "3" ]; then
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  Run: tailscale serve https / http://127.0.0.1:$CADDY_PORT"
    echo ""
fi

echo -e "${GREEN}Installation complete! Your services are running.${NC}"
echo ""
