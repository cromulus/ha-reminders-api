# What's New in v1.1.0

## 🎉 Major Update: Production-Ready Installation

This release transforms the project from a basic integration into a **complete, production-ready stack** with proper architecture, permissions, and multiple deployment options.

---

## ✨ Key Features

### 1. **Path-Based Routing Support**

The HA integration now supports `base_path` configuration!

**Before:**
```
https://your-server.com/lists  ← API must be at root
```

**After v1.1.0:**
```
https://your-server.com/api/lists      ← API at /api
https://your-server.com/mcp/endpoint   ← MCP at /mcp
```

**Configure in Home Assistant:**
- Settings → Devices & Services → Reminders API → Configure
- Add `base_path`: `/api`
- Done!

---

### 2. **Comprehensive Install Script**

**One command to rule them all:**

```bash
bash scripts/install-reminders-stack.sh
```

**What it does:**
- ✅ Installs all dependencies (Caddy, cloudflared, etc.)
- ✅ Creates proper LaunchAgents (runs as YOUR user = has Reminders permissions!)
- ✅ Sets up Caddy reverse proxy for API + MCP
- ✅ Configures Cloudflare Tunnel (recommended) OR Tailscale
- ✅ Creates service scripts and configs
- ✅ Auto-starts everything
- ✅ Tests that it works

**Interactive prompts for:**
- Authentication token (auto-generates if blank)
- Exposure method (Cloudflare/Tailscale/Local)
- Cloudflare credentials (if selected)
- Port configuration
- MCP server installation

---

### 3. **Cloudflare Tunnel Integration** (Recommended)

**Why Cloudflare > Tailscale for this:**
- ✅ More reliable for 24/7 services
- ✅ Free tier is generous
- ✅ Custom domain (reminders.yourdomain.com)
- ✅ Better DDoS protection
- ✅ Built-in analytics
- ✅ No Tailscale license needed

**The script handles everything:**
- Creates tunnel
- Configures DNS
- Sets up LaunchAgent
- Starts automatically

---

### 4. **Proper Architecture**

**Before:**
```
Home Assistant → reminders-api (background daemon)
                 ↓
                 ❌ No Reminders permissions
                 ❌ Returns empty arrays
```

**After v1.1.0:**
```
Internet/Tailscale
     ↓
Cloudflare Tunnel / Tailscale Serve
     ↓
Caddy Reverse Proxy (:443 or :8080)
     ├─→ /api/* → reminders-api (:8081) ✅ LaunchAgent (your user)
     ├─→ /mcp/* → MCP server (:8082)    ✅ LaunchAgent (your user)
     └─→ /health → Health check
```

**Benefits:**
- ✅ Single entry point
- ✅ Path-based routing
- ✅ Easy to add more services
- ✅ Centralized auth/logging
- ✅ Proper permissions
- ✅ Auto-restart on failure
- ✅ Professional setup

---

## 📦 What's Included

### Scripts
- `install-reminders-stack.sh` - Complete automated setup
- `discover-install.sh` - Find what's currently installed
- `uninstall-reminders.sh` - Clean removal
- `setup-proper.sh` - Simple Tailscale-based setup

### Documentation
- `CHANGELOG.md` - Complete version history
- `ISSUE_FOUND.md` - Root cause analysis
- `DEBUG_SESSION.md` - Debugging history
- `DEVELOPMENT.md` - Technical details
- `HANDOFF_SUMMARY.md` - Project state
- `scripts/README.md` - Script usage
- `scripts/SETUP_GUIDE.md` - Manual setup guide

### Integration Changes
- Added `base_path` config field
- Updated API client to support path prefixes
- Better UI descriptions
- Improved error handling

---

## 🚀 Getting Started

### Fresh Installation (Recommended)

```bash
# On aurelius (your Mac):
cd ~/path/to/ha-reminders-api/scripts

# Run the comprehensive installer
bash install-reminders-stack.sh

# Follow the prompts:
# - Enter auth token (or auto-generate)
# - Choose Cloudflare Tunnel (recommended)
# - Enter Cloudflare credentials
# - Enter domain name
# - Choose to install MCP (optional)

# Done! Everything is set up and running
```

### Migrating from Old Setup

```bash
# 1. Discover what's installed
bash discover-install.sh

# 2. Remove old setup
bash uninstall-reminders.sh

# 3. Install properly
bash install-reminders-stack.sh
```

### Home Assistant Configuration

After running the install script:

**Settings → Devices & Services → Add Integration → Reminders API**

```
Name: My Reminders
URL: https://reminders.yourdomain.com  (or Tailscale URL)
Base Path: /api
Token: [the token from install script]
```

**That's it!** Your reminder lists will appear as To-do entities.

---

## 🔧 Architecture Options

The install script offers 4 options:

### 1. Cloudflare Tunnel (Recommended)
```
Internet → CF Tunnel → Caddy → API + MCP
```
- Best for: Production, reliability, custom domain
- Requires: Cloudflare account, domain
- Cost: Free

### 2. Tailscale Funnel (Public)
```
Internet → TS Funnel → Caddy → API + MCP
```
- Best for: Easy setup, no domain needed
- Requires: Tailscale account
- Cost: Free (with limits)

### 3. Tailscale Serve (Private)
```
Your Tailnet → TS Serve → Caddy → API + MCP
```
- Best for: Private use, maximum security
- Requires: Tailscale account
- Cost: Free

### 4. Local Only
```
LAN/VPN → Caddy → API + MCP
```
- Best for: Testing, development
- Requires: Network access
- Cost: Free

---

## 📋 Upgrade Instructions

### From 1.0.x

If you're already using the integration:

1. **Update via HACS** (once pushed)
2. **If using Caddy/path-based routing:**
   - Go to Settings → Devices & Services
   - Click on Reminders API
   - Click Configure
   - Add `base_path`: `/api`
   - Save

3. **If API is at root:**
   - No changes needed!
   - Leave base_path empty

### Recommended: Fresh Install

For best results, do a fresh install with the new script:

```bash
# Remove old setup
bash uninstall-reminders.sh

# Install properly with Cloudflare
bash install-reminders-stack.sh
```

This ensures:
- Proper LaunchAgent setup
- Correct permissions
- Professional architecture
- Everything auto-starts

---

## 🐛 Bug Fixes

### Permission Issue Solved

**Root Cause:** reminders-api was running as a background daemon without Reminders permissions.

**Solution:** Run as LaunchAgent (your user) instead of LaunchDaemon (system).

**The install script handles this automatically.**

### Empty Lists Issue Solved

If you were seeing empty arrays:
- Old setup: Background daemon couldn't access Reminders
- New setup: LaunchAgent runs as your user, has full access

---

## 📊 Version Comparison

| Feature | 1.0.x | 1.1.0 |
|---------|-------|-------|
| Basic integration | ✅ | ✅ |
| Path-based routing | ❌ | ✅ |
| Automated install | ❌ | ✅ |
| Cloudflare Tunnel | ❌ | ✅ |
| Caddy integration | ❌ | ✅ |
| MCP support | ❌ | ✅ |
| LaunchAgent setup | ❌ | ✅ |
| Proper permissions | ❌ | ✅ |
| Multiple services | ❌ | ✅ |
| Production-ready | ⚠️  | ✅ |

---

## 🎯 What This Means for You

### Before v1.1.0
```
Manual setup
 ↓
Permission issues
 ↓
Empty arrays
 ↓
Debugging
 ↓
Frustration 😤
```

### After v1.1.0
```
Run one script
 ↓
Answer prompts
 ↓
Everything works
 ↓
Lists appear ✨
 ↓
Happiness 😊
```

---

## 📚 Next Steps

1. **On aurelius**: Run `install-reminders-stack.sh`
2. **Configure Cloudflare** (or Tailscale)
3. **Add integration in Home Assistant**
4. **Enjoy your reminders!**

See `scripts/README.md` for detailed instructions.

---

## 🙏 Contributing

Found a bug? Have a suggestion?
- Issues: https://github.com/cromulus/ha-reminders-api/issues
- PRs welcome!

This install script can be contributed back to `cromulus/reminders-cli` to benefit all users.

---

## 📝 Summary

**v1.1.0 is a complete overhaul:**
- ✅ Production-ready architecture
- ✅ Automated installation
- ✅ Multiple deployment options
- ✅ Proper permissions
- ✅ Professional setup
- ✅ Everything works out of the box

**Upgrade today and enjoy a hassle-free reminders integration!**
