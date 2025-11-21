# Reminders API Home Assistant Integration

A Home Assistant custom integration that connects to the reminders-api to sync macOS Reminders as native Home Assistant todo lists.

## Features

- ✅ Each reminder list becomes a separate Home Assistant todo entity
- ✅ Full CRUD support (Create, Read, Update, Delete)
- ✅ Set due dates and descriptions
- ✅ Mark items as complete/incomplete
- ✅ GUI-configurable with connection validation
- ✅ Real-time updates (30-second polling)
- ✅ Optional authentication token support

## Requirements

- Home Assistant 2023.11 or later (for todo platform support)
- [reminders-cli](https://github.com/cromulus/reminders-cli) server running on a macOS machine
- Access to Apple Reminders on the macOS machine
- Network connectivity between Home Assistant and the reminders-cli server
- (Optional) API authentication token

## Installation

### Prerequisites - Set up reminders-cli server

Before installing this integration, you need to have reminders-cli running as a server:

1. **On your macOS machine**:
   - Clone or download the repository from [https://github.com/cromulus/reminders-cli](https://github.com/cromulus/reminders-cli)
   - Follow the installation instructions in that repository's README

2. **Start the server**:
   ```bash
   reminders-api --host 127.0.0.1 --port 8080
   ```

   Or with authentication:
   ```bash
   reminders-api --auth-required --token YOUR_TOKEN --host 127.0.0.1 --port 8080
   ```

3. **Test the server** is accessible:
   ```bash
   curl http://localhost:8080/lists
   ```

### Method 1: Manual Installation

1. Copy the `custom_components/reminders_api` directory to your Home Assistant `config/custom_components/` directory:

   ```bash
   cd /path/to/your/home-assistant/config
   mkdir -p custom_components
   cp -r /path/to/ha-reminders-api/custom_components/reminders_api custom_components/
   ```

2. Restart Home Assistant

3. Go to **Settings** → **Devices & Services** → **Add Integration**

4. Search for "Reminders API" and click to add it

### Method 2: HACS (when published)

1. Open HACS
2. Go to Integrations
3. Click the three dots in the top right
4. Select "Custom repositories"
5. Add this repository URL
6. Install "Reminders API"

## Configuration

### Setup via UI

1. Navigate to **Settings** → **Devices & Services**
2. Click **Add Integration**
3. Search for and select **Reminders API**
4. Fill in the configuration:
   - **Name**: A friendly name for this integration (e.g., "My Reminders")
   - **API Server URL**: The URL of your reminders-cli server:
     - If on same machine: `http://localhost:8080`
     - If on different machine: `http://<mac-ip-address>:8080`
   - **API Token** (optional): Your API authentication token if required

5. Click **Submit**

The integration will validate the connection before saving. If the connection fails, you'll see an error message.

### Entities Created

After setup, the integration will create one todo list entity for each of your reminder lists:

- `todo.{list_name}` - Todo list for each reminders list

For example, if you have lists named "Work", "Personal", and "Shopping", you'll get:
- `todo.work`
- `todo.personal`
- `todo.shopping`

## Usage

### In the Home Assistant UI

1. Go to the **To-do** page in the sidebar
2. You'll see all your reminder lists
3. Click on any list to:
   - Add new items
   - Mark items complete/incomplete
   - Edit item details (title, description, due date)
   - Delete items

### In Automations

```yaml
# Example: Add a reminder when someone arrives home
automation:
  - alias: "Add reminder on arrival"
    trigger:
      - platform: state
        entity_id: person.john
        to: "home"
    action:
      - service: todo.add_item
        target:
          entity_id: todo.personal
        data:
          item: "Check the mail"
          due_date: "{{ now().date() }}"
```

```yaml
# Example: Get notification when high-priority items are added
automation:
  - alias: "Notify on new urgent item"
    trigger:
      - platform: state
        entity_id: todo.work
    condition:
      - condition: template
        value_template: "{{ trigger.to_state.state | int > trigger.from_state.state | int }}"
    action:
      - service: notify.mobile_app
        data:
          message: "New work item added!"
```

## API Compatibility

This integration is compatible with reminders-cli server mode. It uses the following endpoints:

- `GET /lists` - Fetch all lists
- `GET /lists/:name` - Fetch reminders from a list
- `POST /lists/:name/reminders` - Create a reminder
- `PATCH /lists/:name/reminders/:id` - Update a reminder
- `PATCH /lists/:name/reminders/:id/complete` - Mark complete
- `PATCH /lists/:name/reminders/:id/uncomplete` - Mark incomplete
- `DELETE /lists/:name/reminders/:id` - Delete a reminder

## Troubleshooting

### Integration won't connect

1. Verify the reminders-cli server is running on your Mac:
   ```bash
   curl http://localhost:8080/lists
   ```

2. Check if authentication is required and token is correct:
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/lists
   ```

3. Check Home Assistant logs for errors:
   ```bash
   tail -f /config/home-assistant.log | grep reminders_api
   ```

### Items not updating

- The integration polls for updates every 30 seconds
- Force a refresh by reloading the integration in Settings → Devices & Services
- Check the coordinator logs for API errors

### Authentication errors

- Ensure your API token is correct if you've configured one
- Verify the reminders-cli server is configured to accept the token
- Most setups don't require a token - try leaving it blank

## Development

### Running Tests

```bash
# Run Home Assistant integration tests
pytest tests/
```

### Debug Logging

Add to your `configuration.yaml`:

```yaml
logger:
  default: info
  logs:
    custom_components.reminders_api: debug
```

## Changelog

### v1.0.1 (2025-10-16)

**Critical and Major Bug Fixes:**
- ✅ Added `CoordinatorEntity` inheritance - entities now auto-update when data changes
- ✅ Added URL encoding for list names with special characters (spaces, &, etc.)
- ✅ Added 30-second HTTP timeouts to prevent integration hangs
- ✅ Added comprehensive error handling with descriptive error messages
- ✅ Optimized updates to avoid redundant API calls (better performance)
- ✅ Added `available` property for accurate entity state when API is down
- ✅ Added `device_info` for proper entity grouping in UI
- ✅ Fixed entity ID generation to handle list names with spaces

For complete details, see `FIXES.md`.

### v1.0.0 (2025-10-16)

**Initial Release:**
- Home Assistant todo list integration for reminders-api
- GUI-configurable setup with health check validation
- Full CRUD support for reminders
- Due dates and descriptions support
- 30-second polling updates
- Optional Bearer token authentication

## Support

For issues, feature requests, or contributions, please visit:
https://github.com/cromulus/ha-reminders-api

## License

This integration is licensed under the MIT License.
