# Development Status & Context

**Last Updated:** 2025-11-20
**Current Version:** 1.0.4 (not yet pushed to GitHub)

## Current Issue

The Home Assistant integration **authenticates successfully** but **does not display any reminder lists**. Users can add the integration and it connects to the reminders-cli server, but no To-do entities are created.

## What We've Done

### 1. Repository Setup
- ✅ Created HACS-compatible repository structure
- ✅ Renamed integration from `reminders_cli` to `reminders_api`
- ✅ Updated all references to use `cromulus/reminders-cli` as the source repository
- ✅ Added proper HACS files: `hacs.json`, `info.md`, `README.md`
- ✅ Added `LICENSE` (MIT) and `.gitignore`

### 2. Debug Improvements (v1.0.4)
Added extensive debug logging to identify why lists aren't showing:

**File: `custom_components/reminders_api/__init__.py`**
- Added logging to show how many lists are returned from API
- Added logging for each list being processed
- Added handling for different list identifier formats (`uuid`, `id`, `name`, `title`)
- Added handling for lists returned as strings vs objects
- Added warning when no lists are returned

**File: `custom_components/reminders_api/api.py`**
- Added logging to show raw API response type and content
- Added handling for different response formats (dict vs list)
- Added fallback logic if API returns `{"lists": [...]}` instead of direct array

### 3. Testing Tools Created

**`custom_components/reminders_api/test_api.sh`** (Recommended)
- Bash script that works in Home Assistant terminal
- Tests the `/lists` endpoint
- Shows HTTP status codes and responses
- Usage:
  ```bash
  cd /config/custom_components/reminders_api
  bash test_api.sh http://YOUR_SERVER_IP:8080 [optional-token]
  ```

**`custom_components/reminders_api/test_api.py`**
- Python script (requires aiohttp)
- Falls back to showing curl commands if aiohttp not available
- More detailed testing when run from proper Python environment

## Current State

### What Works
- ✅ Integration can be added via Home Assistant UI
- ✅ Authentication succeeds
- ✅ Connection test passes
- ✅ No errors in configuration flow

### What Doesn't Work
- ❌ No To-do list entities appear in Home Assistant
- ❌ Lists are not being fetched or displayed

### Hypothesis
The reminders-cli API likely returns data in a format different from what the integration expects. The API might return:
- Just an array of list names (strings)
- A different JSON structure
- Lists under a different key
- Different field names for list metadata

## Next Steps

### 1. Run the Test Script
From the Home Assistant terminal:
```bash
cd /config/custom_components/reminders_api
bash test_api.sh http://YOUR_REMINDERS_SERVER:8080
```

**Look for:**
- What does `/lists` return? (copy the full JSON response)
- Is it a JSON array? JSON object? Array of strings?
- What fields are in each list object?

### 2. Check Home Assistant Logs
After reloading the integration:
```bash
grep reminders_api /config/home-assistant.log | tail -30
```

**Look for these log messages:**
- `Got X lists from API` - How many lists?
- `Raw lists response:` - What's the actual response?
- `Found list:` - Are any lists being detected?
- `Total lists configured:` - Final count

### 3. Compare API Response to Integration Expectations

The integration currently expects the API to return one of:
- `[{list object}, {list object}, ...]` (array of objects)
- `{"lists": [{list object}, ...]}` (object with lists key)

Each list object should have one of these identifier fields:
- `uuid` (preferred)
- `id`
- `name`
- `title`

### 4. Fix the Code Based on Findings

Once we know the actual API response format, update:
- `custom_components/reminders_api/api.py` - `get_lists()` method
- `custom_components/reminders_api/__init__.py` - `_async_update_data()` method

## API Endpoints Expected

The integration uses these endpoint patterns:

```
GET  /lists                                    # Get all lists
GET  /lists/{list_name}                        # Get reminders from a list
POST /lists/{list_name}/reminders              # Create reminder
PATCH /lists/{list_name}/reminders/{id}        # Update reminder
DELETE /lists/{list_name}/reminders/{id}       # Delete reminder
PATCH /lists/{list_name}/reminders/{id}/complete    # Mark complete
PATCH /lists/{list_name}/reminders/{id}/uncomplete  # Mark incomplete
```

See `custom_components/reminders_api/const.py` for the full list.

## Files Modified in v1.0.4

```
custom_components/reminders_api/
├── __init__.py           # Added debug logging, improved list detection
├── api.py                # Added response format handling
├── manifest.json         # Bumped to version 1.0.4
├── test_api.sh           # NEW - Bash test script
└── test_api.py           # NEW - Python test script
```

## Version History

- **v1.0.4** (current, not pushed) - Debug logging and test scripts
- **v1.0.1** - Initial HACS-compatible release
- **v1.0.0** - Original version

## Git Status

**Current branch:** main
**Current commit:** 0a929fb - "Bump version to 1.0.4"
**Tag created:** v1.0.4 (local only)

**To push:**
```bash
git push origin main
git push origin v1.0.4
```

## Documentation Issues to Fix

The README files currently have incorrect server startup commands. Need to:
1. Get the correct command from cromulus/reminders-cli repo
2. Update all README files with correct installation/startup instructions

## Contact & References

- **Main repo:** https://github.com/cromulus/ha-reminders-api
- **reminders-cli repo:** https://github.com/cromulus/reminders-cli
- **HACS:** Users install via custom repository

## Debugging Checklist

When someone picks this up:

- [ ] Run `bash test_api.sh http://SERVER:PORT` and capture output
- [ ] Reload integration in Home Assistant
- [ ] Check logs: `grep reminders_api /config/home-assistant.log`
- [ ] Compare API response format to what integration expects
- [ ] Update code to handle actual API format
- [ ] Test that lists appear
- [ ] Test creating/completing/deleting reminders
- [ ] Update documentation with correct server commands
- [ ] Bump version, tag, and push

## Known Good Configuration

- **Home Assistant:** 2024.1.0+
- **Integration type:** service
- **IoT class:** local_polling
- **Update interval:** 30 seconds
- **Authentication:** Optional Bearer token

## Critical Code Sections

### List Fetching Logic
**File:** `custom_components/reminders_api/api.py:104-121`
```python
async def get_lists(self) -> list[dict[str, Any]]:
    """Get all reminder lists with metadata."""
    # This is where we parse the API response
    # Currently handles dict/list formats
```

### Entity Creation Logic
**File:** `custom_components/reminders_api/__init__.py:83-133`
```python
async def _async_update_data(self) -> dict[str, list[dict]]:
    """Fetch data from API."""
    # This loops through lists and creates coordinator data
    # Entities are created from this data
```

### Entity Setup Logic
**File:** `custom_components/reminders_api/todo.py:26-48`
```python
async def async_setup_entry(...):
    """Set up the Reminders CLI todo platform."""
    # This creates To-do entities from coordinator data
```

---

**Next person: Start by running the test script and checking the logs!**
