# The Right Way: Setting Up reminders-api with Caddy

This guide shows how to properly set up reminders-api and MCP server with Caddy as a reverse proxy.

## Architecture Options

### Option A: Caddy + Tailscale Funnel (Recommended)
```
Internet → Tailscale Funnel → Caddy → reminders-api
                                    → MCP server
```
**Pros:**
- Simple setup with Tailscale
- Built-in authentication via Tailscale
- No need to manage certificates
- Secure by default

### Option B: Caddy + Cloudflare Tunnel
```
Internet → Cloudflare Tunnel → Caddy → reminders-api
                                      → MCP server
```
**Pros:**
- More control over DNS/routing
- Better for multiple services
- DDoS protection included

### Option C: Local Only (Simplest)
```
Home Assistant → Tailscale → Caddy → reminders-api
                                   → MCP server
```
**Pros:**
- No public exposure
- Simplest and most secure
- Perfect if HA and Mac are on same Tailscale network

---

## Prerequisites

### 1. Install Caddy
```bash
brew install caddy
```

### 2. Install reminders-cli (if not already)
Follow instructions at: https://github.com/cromulus/reminders-cli

### 3. Choose Your Exposure Method
- Tailscale (already have)
- Cloudflare (need account + tunnel setup)
- Local only (use existing Tailscale network)

---

## Setup Instructions

### Step 1: Create Directory Structure
```bash
mkdir -p ~/reminders-services
cd ~/reminders-services
```

### Step 2: Create Caddyfile

**For Option A (Tailscale Funnel):**
```Caddyfile
# ~/reminders-services/Caddyfile

# Listen on local port - Tailscale Funnel will handle HTTPS
http://127.0.0.1:8080 {
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

    # MCP server endpoints
    handle /mcp* {
        reverse_proxy localhost:8082
    }

    # Health check
    handle /health {
        respond "OK" 200
    }

    # Token validation middleware
    @authenticated {
        header Authorization "Bearer YOUR_TOKEN_HERE"
    }

    handle @authenticated {
        reverse_proxy localhost:8081
    }

    handle {
        respond "Unauthorized" 401
    }
}
```

**For Option C (Local Only - Simplest):**
```Caddyfile
# ~/reminders-services/Caddyfile

:8080 {
    # reminders-api
    handle /lists* {
        reverse_proxy localhost:8081
    }

    handle /reminders* {
        reverse_proxy localhost:8081
    }

    handle /webhooks* {
        reverse_proxy localhost:8081
    }

    # MCP server
    handle /mcp* {
        reverse_proxy localhost:8082
    }

    # Optional: Add authentication
    basicauth * {
        # Generate with: caddy hash-password
        bill $2a$14$YOUR_HASHED_PASSWORD_HERE
    }
}
```

### Step 3: Create systemd-style Service Scripts

**Create: `~/reminders-services/run-reminders-api.sh`**
```bash
#!/bin/bash
cd ~/reminders-services
exec reminders-api --host 127.0.0.1 --port 8081
```

**Create: `~/reminders-services/run-mcp.sh`** (if you have MCP server)
```bash
#!/bin/bash
cd ~/reminders-services
exec your-mcp-server --host 127.0.0.1 --port 8082
```

**Create: `~/reminders-services/run-caddy.sh`**
```bash
#!/bin/bash
cd ~/reminders-services
exec caddy run --config Caddyfile
```

Make them executable:
```bash
chmod +x ~/reminders-services/*.sh
```

### Step 4: Create LaunchAgents (Run as YOUR User)

**Create: `~/Library/LaunchAgents/com.reminders-api.plist`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.reminders-api</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/reminders-services/run-reminders-api.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/reminders-services/reminders-api.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/reminders-services/reminders-api.error.log</string>
    <key>WorkingDirectory</key>
    <string>/Users/YOUR_USERNAME/reminders-services</string>
</dict>
</plist>
```

**Create: `~/Library/LaunchAgents/com.caddy.plist`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.caddy</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/reminders-services/run-caddy.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/reminders-services/caddy.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/reminders-services/caddy.error.log</string>
    <key>WorkingDirectory</key>
    <string>/Users/YOUR_USERNAME/reminders-services</string>
</dict>
</plist>
```

**Replace `YOUR_USERNAME` with your actual username!**

### Step 5: Load the Services
```bash
launchctl load ~/Library/LaunchAgents/com.reminders-api.plist
launchctl load ~/Library/LaunchAgents/com.caddy.plist
```

### Step 6: Test Locally
```bash
# Test reminders-api through Caddy
curl http://localhost:8080/lists

# Should return your reminder lists!
```

### Step 7: Expose via Tailscale Funnel (Option A)
```bash
# Serve it publicly via Tailscale Funnel
tailscale funnel 8080

# Or if you want Tailscale Serve (private to your tailnet)
tailscale serve https / http://127.0.0.1:8080
```

Your API is now available at: `https://aurelius.koi-neon.ts.net/lists`

---

## Alternative: Cloudflare Tunnel Setup

### Install cloudflared
```bash
brew install cloudflare/cloudflare/cloudflared
```

### Authenticate
```bash
cloudflared tunnel login
```

### Create Tunnel
```bash
cloudflared tunnel create reminders-api
```

### Configure Tunnel
**Create: `~/.cloudflared/config.yml`**
```yaml
tunnel: YOUR_TUNNEL_ID
credentials-file: /Users/YOUR_USERNAME/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: reminders.yourdomain.com
    service: http://localhost:8080
  - service: http_status:404
```

### Run Tunnel
```bash
cloudflared tunnel run reminders-api
```

Or create a LaunchAgent for it (similar to above).

---

## Managing the Services

### Check Status
```bash
# Check if services are running
launchctl list | grep com.reminders-api
launchctl list | grep com.caddy

# Check logs
tail -f ~/reminders-services/reminders-api.log
tail -f ~/reminders-services/caddy.log
```

### Stop Services
```bash
launchctl unload ~/Library/LaunchAgents/com.reminders-api.plist
launchctl unload ~/Library/LaunchAgents/com.caddy.plist
```

### Start Services
```bash
launchctl load ~/Library/LaunchAgents/com.reminders-api.plist
launchctl load ~/Library/LaunchAgents/com.caddy.plist
```

### Restart Services
```bash
launchctl unload ~/Library/LaunchAgents/com.reminders-api.plist
launchctl load ~/Library/LaunchAgents/com.reminders-api.plist
```

---

## Recommendation

**For your use case (Home Assistant integration):**

**Use Option C (Local Only via Tailscale)**

1. Run reminders-api + Caddy as LaunchAgents (runs as your user, has Reminders permissions)
2. Use Tailscale Serve (NOT Funnel) to keep it private to your tailnet
3. Home Assistant connects via Tailscale

**Why this is best:**
- ✅ Secure (only accessible on your Tailscale network)
- ✅ Simple (no public exposure needed)
- ✅ Proper permissions (runs as your user)
- ✅ Easy to manage
- ✅ Caddy adds auth + routing flexibility

**Command:**
```bash
tailscale serve https / http://127.0.0.1:8080
```

Home Assistant connects to: `https://aurelius.koi-neon.ts.net`

---

## Troubleshooting

### Services won't start
Check logs:
```bash
tail -f ~/reminders-services/*.log
```

### Permission denied accessing Reminders
1. System Preferences → Security & Privacy → Privacy → Reminders
2. Add Terminal (or whatever is running the service)
3. Restart the service

### Can't connect
```bash
# Test each layer:
curl http://localhost:8081/lists  # Direct to reminders-api
curl http://localhost:8080/lists  # Through Caddy
curl https://aurelius.koi-neon.ts.net/lists  # Through Tailscale
```

---

## Quick Setup Script

Want me to create a single setup script that does all this for you?
