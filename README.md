# Home Assistant Reminders API Integration

[![hacs_badge](https://img.shields.io/badge/HACS-Custom-41BDF5.svg)](https://github.com/hacs/integration)

A Home Assistant custom integration for managing Apple Reminders through the Reminders API.

## Features

- Create and manage reminders in Apple Reminders
- Expose reminders as To-do entities in Home Assistant
- Create automations based on reminder events
- Full support for reminder lists
- Complete/uncomplete reminders
- Webhook support for real-time updates

## Prerequisites

### 1. Reminders CLI Server
This integration requires the reminders-cli tool from [https://github.com/cromulus/reminders-cli](https://github.com/cromulus/reminders-cli) to be installed and running as a server on a macOS machine that has access to your Apple Reminders.

**Setting up reminders-cli server:**

1. **Download and install reminders-cli on your macOS machine:**
   - Clone or download the repository from [https://github.com/cromulus/reminders-cli](https://github.com/cromulus/reminders-cli)
   - Follow the installation instructions in that repository's README

2. **Start the reminders-cli server:**
   ```bash
   reminders serve --port 8080
   ```

3. **Ensure the server is accessible from your Home Assistant instance:**
   - If running on the same machine: Use `http://localhost:8080`
   - If running on a different machine: Use `http://<mac-ip-address>:8080`
   - Test connectivity: `curl http://<server-address>:8080/lists`

**Important Notes:**
- The reminders-cli server must remain running for the integration to work
- The server needs to run on a macOS machine with access to your iCloud Reminders
- Consider running the server as a background service for reliability
- The server provides a REST API that this integration uses to communicate with Apple Reminders

### 2. Home Assistant Requirements
- Home Assistant 2024.1.0 or higher (for To-do platform support)

## Installation

### HACS (Recommended)

1. Open HACS in Home Assistant
2. Click on "Integrations"
3. Click the three dots menu in the top right
4. Select "Custom repositories"
5. Add this repository URL: `https://github.com/cromulus/ha-reminders-api`
6. Select "Integration" as the category
7. Click "Add"
8. Find "Reminders API" in the integrations list
9. Click "Download"
10. Restart Home Assistant
11. Go to Settings → Devices & Services
12. Click "Add Integration"
13. Search for "Reminders API"
14. Follow the configuration steps

### Manual Installation

1. Download the `custom_components/reminders_api` directory from this repository
2. Copy it to your Home Assistant `custom_components` directory
3. Restart Home Assistant
4. Go to Settings → Devices & Services
5. Click "Add Integration"
6. Search for "Reminders API"
7. Follow the configuration steps

## Configuration

When adding the integration, you'll need to provide:

- **Name**: A friendly name for the integration instance (e.g., "My Reminders")
- **URL**: The URL of your reminders-cli server:
  - Same machine: `http://localhost:8080`
  - Different machine on network: `http://<mac-ip-address>:8080`
  - Custom port: `http://<address>:<port>`
- **Token**: Optional authentication token (leave blank if not configured on the server)

## Usage

Once configured, the integration will:

1. Create To-do entities for each of your reminder lists
2. Sync reminders between Home Assistant and Apple Reminders
3. Allow you to create, complete, and delete reminders through Home Assistant

### Services

The integration provides the following services:

- `todo.add_item`: Create a new reminder
- `todo.update_item`: Update an existing reminder
- `todo.remove_item`: Delete a reminder

### Automations

Example automation to create a reminder:

```yaml
automation:
  - alias: "Create Grocery Reminder"
    trigger:
      platform: state
      entity_id: binary_sensor.fridge_door
      to: "on"
      for: "00:05:00"
    action:
      service: todo.add_item
      target:
        entity_id: todo.reminders_api_groceries
      data:
        item: "Check what's needed from the grocery store"
```

## Support

For issues, feature requests, or questions, please open an issue on the [GitHub repository](https://github.com/cromulus/ha-reminders-api/issues).

## License

This project is licensed under the MIT License - see the LICENSE file for details.