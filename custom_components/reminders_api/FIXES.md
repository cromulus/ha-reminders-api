# Home Assistant Integration - Required Fixes

## Critical Issues (Must Fix Before Use)

### #1: Missing CoordinatorEntity Inheritance ⚠️ CRITICAL
**File**: `todo.py:41`
**Problem**: Entity doesn't automatically update when coordinator fetches new data
**Current**:
```python
class RemindersTodoListEntity(TodoListEntity):
```
**Fix**: Inherit from both CoordinatorEntity and TodoListEntity
```python
class RemindersTodoListEntity(CoordinatorEntity, TodoListEntity):
    def __init__(self, coordinator, list_name):
        super().__init__(coordinator)
```
**Impact**: Without this, entities never update after initial creation

---

### #2: Entities Created Before Data Loaded ⚠️ CRITICAL
**File**: `todo.py:30-36`
**Problem**: Entity setup happens before coordinator fetches initial data
**Current Flow**:
```python
# __init__.py
coordinator = RemindersDataUpdateCoordinator(...)  # lists_data = {}
await hass.config_entries.async_forward_entry_setups(...)  # Creates entities
await coordinator.async_config_entry_first_refresh()  # Gets data
```
**Fix**: Use update listener pattern to create entities after first refresh
**Impact**: Integration starts with zero entities until reload

---

### #3: No URL Encoding ⚠️ CRITICAL
**File**: `api.py:88, 102, 124, 142, 149, 156`
**Problem**: List names with spaces/special chars create malformed URLs
**Example**: List name "Work & Home" → `/lists/Work & Home` (invalid)
**Fix**: URL-encode list names
```python
from urllib.parse import quote
endpoint = ENDPOINT_LIST_REMINDERS.format(list_name=quote(list_name, safe=''))
```
**Impact**: Crashes on lists with special characters

---

### #4: No HTTP Timeouts ⚠️ CRITICAL
**File**: `api.py:59`
**Problem**: Hung requests block indefinitely
**Fix**: Add timeout to all requests
```python
timeout = aiohttp.ClientTimeout(total=30)
async with self._session.request(..., timeout=timeout):
```
**Impact**: Integration can hang Home Assistant

---

## Major Issues (Should Fix Soon)

### #5: No Error Handling in Entity Operations
**File**: `todo.py:92, 102, 140`
**Problem**: API failures propagate but user sees no feedback
**Fix**: Wrap operations in try/except, raise HomeAssistantError
```python
from homeassistant.exceptions import HomeAssistantError

try:
    await self.coordinator.api.create_reminder(...)
except Exception as err:
    raise HomeAssistantError(f"Failed to create reminder: {err}") from err
```
**Impact**: Silent failures, confusing UX

---

### #6: Double API Calls on Update
**File**: `todo.py:119-136`
**Problem**: Calls complete/uncomplete AND update_reminder with same data
**Fix**: Only call update_reminder if non-status fields changed
```python
# Call complete/uncomplete if status changed
if is_completed != was_completed:
    ...

# Only update other fields if they actually changed
if (item.summary != current_reminder.get("title") or
    item.description != current_reminder.get("notes") or
    item.due != self._parse_due_date(current_reminder.get("dueDate"))):
    await self.coordinator.api.update_reminder(...)
```
**Impact**: 2x API load, slower operations

---

### #7: Missing `available` Property
**File**: `todo.py:41`
**Problem**: Entities show as available even when API is down
**Fix**: Add available property
```python
@property
def available(self) -> bool:
    return self.coordinator.last_update_success
```
**Impact**: Misleading UI state

---

### #8: Missing `device_info`
**File**: `todo.py:41`
**Problem**: Entities not grouped under a device
**Fix**: Add device_info property
```python
@property
def device_info(self):
    return {
        "identifiers": {(DOMAIN, self.coordinator.entry.entry_id)},
        "name": "Reminders CLI",
        "manufacturer": "Apple",
        "model": "macOS Reminders",
    }
```
**Impact**: Poor organization in UI

---

### #9: Unused Imports
**Files**: `api.py:4`, `todo.py:6`
**Problem**: Unnecessary imports
**Fix**: Remove:
- `api.py`: `import asyncio`
- `todo.py`: `from typing import cast`

---

## Medium Priority Issues

### #10: No Type Hint for `hass`
**File**: `api.py:31`
**Fix**: Add type hint
```python
def __init__(self, hass: HomeAssistant, url: str, ...):
```

---

### #11: Missing URL Validation in Config Flow
**File**: `config_flow.py`
**Problem**: Accepts invalid URLs like "hello"
**Fix**: Use vol.Url() validator
```python
import voluptuous as vol
from homeassistant.helpers import config_validation as cv

vol.Required(CONF_URL): vol.Url(),
```

---

### #12: No API Response Validation
**File**: `api.py:84, 86, etc`
**Problem**: Assumes API always returns expected structure
**Fix**: Validate responses or use Pydantic models

---

### #13: Entity ID Safety
**File**: `todo.py:61`
**Problem**: List names with spaces create messy entity IDs
**Fix**: Slugify list name
```python
from homeassistant.util import slugify
self._attr_unique_id = f"{coordinator.entry.entry_id}_{slugify(list_name)}"
```

---

## Nice to Have

### #14: Dynamic Entity Management
**Problem**: New lists don't appear until integration reload
**Fix**: Implement entry update listener

### #15: Options Flow
**Problem**: Can't change URL/token after setup
**Fix**: Implement config_flow.py async_step_init for options

### #16: Retry Logic
**Problem**: No retry on transient failures
**Fix**: Add exponential backoff

### #17: Webhook Support (Currently Incomplete)
**Problem**: Webhook registration code exists but never used
**Fix**: Actually implement webhook setup in coordinator

---

## Implementation Order

**Phase 1 - Critical (Required for basic functionality):**
1. #1 - CoordinatorEntity inheritance
2. #2 - Entity creation timing
3. #3 - URL encoding
4. #4 - HTTP timeouts

**Phase 2 - Major (Required for production):**
5. #5 - Error handling
6. #6 - Remove double API calls
7. #7 - Available property
8. #8 - Device info
9. #9 - Remove unused imports

**Phase 3 - Polish:**
10-13. Type hints, validation, entity ID safety

**Phase 4 - Enhancements:**
14-17. Dynamic entities, options flow, retry, webhooks
