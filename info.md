# Reminders API Integration

## What is this?

This integration connects Home Assistant to Apple Reminders through the reminders-cli server, allowing you to manage your Apple Reminders directly from Home Assistant.

## Key Features

- **To-do Entities**: Each reminder list becomes a To-do entity in Home Assistant
- **Two-way Sync**: Changes in Home Assistant sync to Apple Reminders and vice versa
- **Automation Support**: Create powerful automations based on reminder events
- **Webhook Support**: Real-time updates when reminders change
- **Simple Configuration**: Easy setup through the Home Assistant UI

## Requirements

⚠️ **Important**: This integration requires the reminders-cli from [https://github.com/cromulus/reminders-cli](https://github.com/cromulus/reminders-cli) to be running as a server on a macOS machine with access to your Apple Reminders.

**Quick Setup:**
1. Clone/download the repository: [https://github.com/cromulus/reminders-cli](https://github.com/cromulus/reminders-cli)
2. Follow the installation instructions in that repository
3. Start the server:
```bash
reminders serve --port 8080
```

The server must be accessible from your Home Assistant instance.

## Setup

1. Install through HACS
2. Restart Home Assistant
3. Add the integration from Settings → Devices & Services
4. Enter your Reminders API server URL
5. Start managing your reminders!

## Example Use Cases

- Create reminders from automations
- Get notifications when reminders are due
- Display reminders on dashboards
- Voice control through Home Assistant Assist
- Integrate with other services and automations

## Support

Need help? Check out:
- [Documentation](https://github.com/cromulus/ha-reminders-api)
- [Issue Tracker](https://github.com/cromulus/ha-reminders-api/issues)

## Changelog

### Version 1.0.0
- Initial release
- Full CRUD operations for reminders
- To-do entity support
- Webhook integration
- HACS compatibility