# Setup Scripts for reminders-api

These scripts help you properly set up reminders-api with Caddy on aurelius (or any Mac).

## The Problem We're Solving

Your reminders-api was installed as a background task/daemon which:
- ❌ Runs in a restricted context without Reminders permissions
- ❌ Can't access your user's Apple Reminders database
- ❌ Returns empty arrays even though reminders-cli command works

## The Solution

Run reminders-api as a **LaunchAgent** (not LaunchDaemon) which:
- ✅ Runs as YOUR user
- ✅ Has access to YOUR Reminders
- ✅ Properly managed by macOS
- ✅ Starts automatically on login
- ✅ Behind Caddy for routing + auth

---

## Quick Start (3 Steps)

### On aurelius:

1. **Discover what's currently installed:**
   ```bash
   bash discover-install.sh
   ```

2. **Uninstall the old setup:**
   ```bash
   bash uninstall-reminders.sh
   ```

3. **Install the proper way:**
   ```bash
   bash setup-proper.sh
   ```

Done! Your reminders-api will now work properly.

---

## Scripts

### `discover-install.sh`
**What it does:** Scans your system to find all reminders-api components

**Output:**
- LaunchDaemons (system-level, ❌ wrong)
- LaunchAgents (user-level, ✅ correct)
- Binaries in /usr/local/bin, etc.
- Running processes
- Config directories
- Log files
- Homebrew packages
- Git repositories

**Run it to see what was installed by the install script.**

---

### `uninstall-reminders.sh`
**What it does:** Removes all reminders-api components

**It will:**
- Stop running processes
- Unload launchd services
- Remove plist files
- Remove binaries
- Remove config directories
- Remove log files
- Optionally uninstall Homebrew packages

**Requires confirmation before removing anything.**

**Note:** Does NOT remove source code (git repos). You can delete those manually if desired.

---

### `setup-proper.sh`
**What it does:** Automated setup of reminders-api + Caddy as LaunchAgents

**Interactive prompts:**
1. Auth token (optional)
2. Port for Caddy (default 8080)
3. Exposure method:
   - Local only via Tailscale Serve (recommended)
   - Public via Tailscale Funnel
   - Manual configuration

**What it creates:**
```
~/reminders-services/
├── Caddyfile                      # Caddy configuration
├── run-reminders-api.sh           # Startup script for API
├── run-caddy.sh                   # Startup script for Caddy
├── reminders-api.log              # API logs
├── reminders-api.error.log        # API errors
├── caddy.log                      # Caddy logs
└── caddy.error.log                # Caddy errors

~/Library/LaunchAgents/
├── com.reminders-api.plist        # API service
└── com.caddy.plist                # Caddy service
```

**After setup:**
- Services auto-start on login
- Services auto-restart if they crash
- Logs are written to `~/reminders-services/`
- API accessible at `http://localhost:8080/lists`

---

## Architecture

```
[Home Assistant] → [Tailscale] → [Caddy :8080] → [reminders-api :8081]
                                              → [MCP server :8082] (optional)
```

**Benefits:**
- ✅ Caddy handles routing, auth, HTTPS
- ✅ reminders-api runs as your user (has Reminders permissions)
- ✅ Everything auto-starts and auto-restarts
- ✅ Logs are centralized
- ✅ Easy to manage with launchctl

---

## After Setup

### Test locally:
```bash
curl http://localhost:8080/lists
# Should return your reminder lists!
```

### Setup Tailscale:
```bash
# Option 1: Private (only your tailnet)
tailscale serve https / http://127.0.0.1:8080

# Option 2: Public (anyone with link)
tailscale funnel 8080
```

### Check status:
```bash
# List services
launchctl list | grep com.reminders-api
launchctl list | grep com.caddy

# View logs
tail -f ~/reminders-services/reminders-api.log
tail -f ~/reminders-services/caddy.log
```

### Manage services:
```bash
# Stop
launchctl unload ~/Library/LaunchAgents/com.reminders-api.plist

# Start
launchctl load ~/Library/LaunchAgents/com.reminders-api.plist

# Restart
launchctl unload ~/Library/LaunchAgents/com.reminders-api.plist
launchctl load ~/Library/LaunchAgents/com.reminders-api.plist
```

---

## Detailed Guide

See `SETUP_GUIDE.md` for:
- Architecture options explained
- Manual setup instructions
- Cloudflare Tunnel alternative
- Advanced Caddy configuration
- Troubleshooting guide

---

## Recommendation

**For Home Assistant integration:**

Use **Option 1: Local only via Tailscale Serve**

```bash
# After running setup-proper.sh:
tailscale serve https / http://127.0.0.1:8080
```

**Why:**
- ✅ Simple and secure
- ✅ No public exposure
- ✅ Home Assistant connects via Tailscale
- ✅ Built-in encryption
- ✅ Easy to set up

Your API will be at: `https://aurelius.koi-neon.ts.net`

---

## Troubleshooting

### Services won't start
```bash
# Check logs
tail -f ~/reminders-services/*.error.log

# Try running manually
~/reminders-services/run-reminders-api.sh
~/reminders-services/run-caddy.sh
```

### Permission denied
1. System Preferences → Security & Privacy → Privacy → **Reminders**
2. Add Terminal (or grant Full Disk Access)
3. Restart services

### Empty arrays returned
- Check that services are running as YOUR user: `ps aux | grep reminders-api`
- Verify reminders-cli command works: `reminders show-lists`
- Check API directly: `curl http://localhost:8081/lists`

### Can't connect from Home Assistant
```bash
# Test each layer:
curl http://localhost:8081/lists          # Direct API
curl http://localhost:8080/lists          # Through Caddy
curl https://aurelius.koi-neon.ts.net/lists  # Through Tailscale
```

---

## Summary

1. ✅ **Run `discover-install.sh`** to see what's installed
2. ✅ **Run `uninstall-reminders.sh`** to remove old setup
3. ✅ **Run `setup-proper.sh`** to install properly
4. ✅ **Run `tailscale serve`** to expose via Tailscale
5. ✅ **Configure Home Assistant** to use `https://aurelius.koi-neon.ts.net`

Now your reminders will appear in Home Assistant!
