"""Constants for the Reminders API integration."""

DOMAIN = "reminders_api"

# Configuration and options
CONF_NAME = "name"
CONF_URL = "url"
CONF_TOKEN = "token"

# Defaults
DEFAULT_NAME = "Reminders"
DEFAULT_PORT = 8080

# Update interval
UPDATE_INTERVAL = 30  # seconds

# API Endpoints
ENDPOINT_LISTS = "/lists"
ENDPOINT_LIST_REMINDERS = "/lists/{list_name}"
ENDPOINT_CREATE_REMINDER = "/lists/{list_name}/reminders"
ENDPOINT_UPDATE_REMINDER = "/lists/{list_name}/reminders/{reminder_id}"
ENDPOINT_DELETE_REMINDER = "/lists/{list_name}/reminders/{reminder_id}"
ENDPOINT_COMPLETE_REMINDER = "/lists/{list_name}/reminders/{reminder_id}/complete"
ENDPOINT_UNCOMPLETE_REMINDER = "/lists/{list_name}/reminders/{reminder_id}/uncomplete"
ENDPOINT_WEBHOOKS = "/webhooks"
