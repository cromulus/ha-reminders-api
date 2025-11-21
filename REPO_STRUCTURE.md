# Repository Structure

This repository contains **only** the Home Assistant integration for reminders-api.

## What's in This Repo

✅ **Home Assistant Custom Integration**
- `custom_components/reminders_api/` - The integration code
- Configuration UI for connecting to reminders-api server
- Path-based routing support (`base_path` option)
- To-do list entities for reminder lists
- Full CRUD operations

✅ **Documentation**
- Installation instructions for the integration
- Configuration guide
- Troubleshooting
- Changelog

✅ **HACS Support**
- `hacs.json` - HACS configuration
- `info.md` - Store display
- Proper versioning and releases

## What's NOT in This Repo

❌ **Server Installation Scripts**
- These belong in [cromulus/reminders-cli](https://github.com/cromulus/reminders-cli)
- Install scripts for reminders-api server
- Caddy configuration
- Cloudflare Tunnel setup
- Service management

❌ **Server Code**
- The actual reminders-api server
- macOS Reminders access code
- API implementation

---

## Clear Separation

### This Repo: `ha-reminders-api`
**Purpose:** Home Assistant Integration Only

**Contents:**
- Integration code
- HA configuration UI
- HA documentation
- HACS metadata

**Users Install:**
- Via HACS (or manual copy)
- In Home Assistant

**Users Configure:**
- URL to existing reminders-api server
- Base path (if using reverse proxy)
- Auth token

---

### Other Repo: `reminders-cli`
**Purpose:** Server Installation & Management

**Contents:**
- reminders-api server code
- Installation scripts
- Service setup (LaunchAgents)
- Reverse proxy configuration (Caddy)
- Cloudflare Tunnel setup
- Server documentation

**Users Install:**
- On macOS machine with Reminders access
- Using install script

**Users Run:**
- Server on Mac
- Exposed via Cloudflare/Tailscale

---

## How They Work Together

```
┌─────────────────────────────────────┐
│         cromulus/reminders-cli       │
│                                      │
│  - reminders-api server code         │
│  - install-reminders-stack.sh       │
│  - Caddy + Cloudflare setup         │
│  - LaunchAgent configuration        │
│                                      │
│  Installs on: macOS                  │
│  Provides: API server                │
└──────────────┬──────────────────────┘
               │
               │ HTTP API
               │
┌──────────────▼──────────────────────┐
│      cromulus/ha-reminders-api      │
│                                      │
│  - Home Assistant integration        │
│  - Config flow UI                    │
│  - To-do list entities               │
│  - Path-based routing support        │
│                                      │
│  Installs via: HACS                  │
│  Runs in: Home Assistant             │
└─────────────────────────────────────┘
```

---

## Installation Flow

### 1. Server Setup (on Mac)
```bash
# In cromulus/reminders-cli repo:
git clone https://github.com/cromulus/reminders-cli.git
cd reminders-cli
bash install-reminders-stack.sh
```

Result: Server running at https://reminders.yourdomain.com

### 2. Integration Setup (in Home Assistant)
```
HACS → Integrations → Custom Repositories
Add: https://github.com/cromulus/ha-reminders-api
Install: Reminders API

Settings → Devices & Services → Add Integration
Search: Reminders API
Configure:
  - URL: https://reminders.yourdomain.com
  - Base Path: /api
  - Token: [from server setup]
```

Result: Reminder lists appear as To-do entities

---

## For Contributors

### Contributing to the Integration (this repo)
- Bug fixes in HA integration
- UI improvements
- Entity features
- Documentation

### Contributing to the Server (other repo)
- Server installation improvements
- Deployment options
- Service management
- Server documentation

---

## Version Compatibility

| HA Integration | Server Version | Notes |
|----------------|----------------|-------|
| 1.1.0+         | Any with API   | Path-based routing |
| 1.0.x          | Any with API   | Root only |

The integration is version-agnostic to the server - as long as the server provides the expected API endpoints, any version works.

---

## Support

### Integration Issues (this repo)
- Not connecting to server
- Configuration problems
- Entity not appearing
- HA-specific errors

Open issue: https://github.com/cromulus/ha-reminders-api/issues

### Server Issues (other repo)
- Installation problems
- Permission errors
- Server not starting
- Empty arrays from API
- Deployment questions

Open issue: https://github.com/cromulus/reminders-cli/issues

---

## Quick Links

- **This Repo:** https://github.com/cromulus/ha-reminders-api
- **Server Repo:** https://github.com/cromulus/reminders-cli
- **HACS:** Install via custom repository
- **Docs:** See README.md in each repo
