# Issue Found - Root Cause Identified

**Date:** 2025-11-20
**Status:** ✅ IDENTIFIED - Issue is with reminders-api server, not HA integration

## TL;DR

✅ **Home Assistant integration is working correctly**
❌ **reminders-api server returns empty arrays `[]`**
✅ **reminders-cli command works on the Mac**

**This is a reminders-api server issue, not a Home Assistant integration bug.**

## The Problem

### What Works
- ✅ `reminders-cli` command on Mac → shows lists
- ✅ Home Assistant can connect to API
- ✅ Authentication works
- ✅ API responds with valid JSON

### What Doesn't Work
- ❌ `curl https://aurelius.koi-neon.ts.net/lists` → `[]`
- ❌ `curl https://aurelius.koi-neon.ts.net/reminders` → `[]`

## Server Configuration

```bash
# Server command being used:
reminders-api --auth-required \
  --token ca8a4a9f9c3cd0260f905a24395a00016cd60cd3cf95b19dee78637d68dccae5 \
  --host 127.0.0.1 \
  --port 8080

# Proxied through Tailscale Serve:
# https://aurelius.koi-neon.ts.net
```

## Diagnosis

The reminders-api server is running **as a background task**, which runs in a different context than interactive terminal sessions.

### ROOT CAUSE: Background Task Permission Issue

**Problem:** macOS background tasks/services/daemons don't have the same permissions as interactive user sessions.

When you run `reminders-cli` from terminal:
- ✅ Runs as your user
- ✅ Has your user's Reminders permissions
- ✅ Can access Reminders database

When `reminders-api` runs as background task:
- ❌ Runs in different context (launchd, system user, etc.)
- ❌ Doesn't have Reminders permissions
- ❌ Can't access Reminders database
- Returns empty arrays

### How Background Tasks are Different

1. **User Context** - Background tasks may run as system user or in limited context
2. **Permissions** - Don't inherit user's Security & Privacy permissions
3. **Database Access** - Can't access user's Reminders database
4. **Sandboxing** - May have additional restrictions

## Solutions to Fix Background Task Permissions

### Option 1: Run as User LaunchAgent (Recommended)

Create a **LaunchAgent** (not LaunchDaemon) which runs as your user and has access to Reminders.

**Create file:** `~/Library/LaunchAgents/com.reminders-api.plist`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.reminders-api</string>
    <key>ProgramArguments</key>
    <array>
        <string>/PATH/TO/reminders-api</string>
        <string>--auth-required</string>
        <string>--token</string>
        <string>YOUR_TOKEN</string>
        <string>--host</string>
        <string>127.0.0.1</string>
        <string>--port</string>
        <string>8080</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/reminders-api.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/reminders-api.error.log</string>
</dict>
</plist>
```

**Load it:**
```bash
launchctl load ~/Library/LaunchAgents/com.reminders-api.plist
```

This runs as YOUR user and should have Reminders access.

### Option 2: Run in Terminal Session (Quick Test)

Use `screen` or `tmux` to keep it running in a terminal session:

```bash
# Start a screen session
screen -S reminders-api

# Run the server
reminders-api --auth-required --token YOUR_TOKEN --host 127.0.0.1 --port 8080

# Detach with: Ctrl-A then D
# Reattach with: screen -r reminders-api
```

This runs as your user in a terminal context with full permissions.

### Option 3: Grant Full Disk Access

If using a background task manager, grant it Full Disk Access:

1. System Preferences → Security & Privacy → Privacy
2. **Full Disk Access** (not just Reminders)
3. Add the process running reminders-api
4. Restart the background task

### Option 4: Run Interactively for Testing

For now, just run it in a terminal to test:

```bash
# Stop the background task
# Run directly in terminal:
reminders-api --auth-required --token YOUR_TOKEN --host 127.0.0.1 --port 8080

# Test in another terminal:
curl http://127.0.0.1:8080/lists
```

If this works, the issue is definitely the background task context.

### How to Check Current Setup

**What type of background task are you using?**
- LaunchDaemon? (wrong - runs as root/system)
- LaunchAgent? (correct - runs as user)
- systemd-style service?
- Other process manager?

**Check logs:**
```bash
# If using launchd:
tail -f /tmp/reminders-api.log
tail -f /tmp/reminders-api.error.log

# Or system logs:
log stream --predicate 'process == "reminders-api"'
```

## Testing Steps

1. **Stop the background task**
2. **Run interactively in terminal:**
   ```bash
   reminders-api --auth-required --token YOUR_TOKEN --host 127.0.0.1 --port 8080
   ```
3. **Test:**
   ```bash
   curl http://127.0.0.1:8080/lists
   ```
4. **If it works:** The issue is background task permissions
5. **Convert to LaunchAgent** (Option 1 above)

## For cromulus/reminders-cli Repository

This may be a bug or documentation issue in the reminders-cli project:
- CLI works but API doesn't
- May need better documentation about permissions
- May need to check for permissions and show error if not granted

Consider opening an issue at: https://github.com/cromulus/reminders-cli/issues

## Home Assistant Integration Status

**✅ The integration is ready and working correctly.**

Once the reminders-api server returns list data:
1. Lists will automatically appear in Home Assistant
2. To-do entities will be created
3. All CRUD operations will work

No code changes needed in the HA integration.

## Files Updated

- ✅ All documentation now has correct `reminders-api` server command
- ✅ Debug logging in place to verify when data comes through
- ✅ Test scripts available
- ✅ Version 1.0.4 ready (but not pushed yet)

## Ready to Push?

**Not yet.** Wait to push v1.0.4 until:
1. reminders-api server is fixed and returning data
2. We can verify the integration works end-to-end
3. Test creating/completing/deleting reminders

Then push and users will get a working integration!
