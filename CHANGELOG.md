# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-11-20

### Added
- **Path-based routing support**: Added `base_path` configuration option to support services behind reverse proxies with path-based routing (e.g., `/api`)
- **Comprehensive install script**: Created `install-reminders-stack.sh` for complete setup including:
  - reminders-api + MCP server + Caddy reverse proxy
  - Cloudflare Tunnel integration (recommended)
  - Tailscale Funnel/Serve support
  - LaunchAgent creation for proper permissions
  - Automatic service management
- **Discovery and uninstall scripts**: Tools to identify and remove existing installations
- **Detailed setup guides**: Multiple setup options with architecture explanations

### Changed
- **Configuration UI**: Added base_path field with helpful descriptions
- **API Client**: Now supports optional base path prepending to all endpoints
- **Documentation**: Complete rewrite with proper architecture explanations

### Fixed
- **Permission issues**: Documented background task permission problem
- **Installation method**: LaunchAgents (run as user) instead of LaunchDaemons (run as system)
- **Caddy integration**: Proper reverse proxy setup for multiple services

### Documentation
- Added `ISSUE_FOUND.md` - Complete root cause analysis
- Added `DEBUG_SESSION.md` - Debugging history and solutions
- Added `DEVELOPMENT.md` - Technical implementation details
- Added `HANDOFF_SUMMARY.md` - Complete work session summary
- Added `scripts/README.md` - Script usage guide
- Added `scripts/SETUP_GUIDE.md` - Detailed manual setup
- Updated all READMEs with correct commands and architecture

## [1.0.4] - 2025-11-20 (Not Released)

### Added
- Debug logging throughout integration
- API test scripts (bash and python)
- Support for multiple list identifier formats
- Better error handling and logging

### Changed
- Improved list detection logic
- Better handling of empty API responses
- Enhanced debugging capabilities

## [1.0.0] - 2025-11-20

### Added
- Initial HACS-compatible release
- Configuration flow with validation
- To-do list entities for reminder lists
- Full CRUD operations for reminders
- 30-second polling updates
- Optional Bearer token authentication
- Webhook support

---

## Upgrade Instructions

### From 1.0.x to 1.1.0

**If you're using path-based routing** (e.g., Caddy serving API at `/api`):

1. Update integration via HACS
2. Go to Settings → Devices & Services
3. Click on Reminders API integration
4. Click Configure
5. Add base path (e.g., `/api`)
6. Save

**If API is at root** (no path prefix):
- No configuration changes needed
- Leave base_path empty

### Fresh Installation

For new installations, use the comprehensive install script:

```bash
bash scripts/install-reminders-stack.sh
```

This will:
- Install all dependencies
- Configure services properly
- Set up reverse proxy
- Create LaunchAgents (runs as your user)
- Configure Cloudflare Tunnel or Tailscale

See `scripts/README.md` for details.

---

## Breaking Changes

### 1.1.0
- None - backwards compatible
- Default base_path is empty (root), maintaining existing behavior

---

## Known Issues

### 1.1.0
- If reminders-api runs as background daemon (not LaunchAgent), it won't have Reminders permissions
- Solution: Use the install script or migrate to LaunchAgent manually

### All Versions
- Requires reminders-cli server to be running and accessible
- macOS only for reminders-cli server
- Server must have Reminders permissions

---

## Coming Soon

- [ ] Automatic webhook registration
- [ ] Real-time updates instead of 30-second polling
- [ ] Support for reminder priorities
- [ ] Support for reminder notes/descriptions
- [ ] Better error messages in UI

---

## Support

- Issues: https://github.com/cromulus/ha-reminders-api/issues
- Discussions: https://github.com/cromulus/ha-reminders-api/discussions
- reminders-cli: https://github.com/cromulus/reminders-cli
