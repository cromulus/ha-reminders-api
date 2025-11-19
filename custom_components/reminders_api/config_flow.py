"""Config flow for Reminders CLI integration."""
from __future__ import annotations

import logging
from typing import Any

import voluptuous as vol
from homeassistant import config_entries
from homeassistant.const import CONF_URL
from homeassistant.data_entry_flow import FlowResult
from homeassistant.helpers import config_validation as cv

from .api import RemindersAPIClient
from .const import CONF_NAME, CONF_TOKEN, DEFAULT_NAME, DOMAIN

_LOGGER = logging.getLogger(__name__)


class RemindersConfigFlow(config_entries.ConfigFlow, domain=DOMAIN):
    """Handle a config flow for Reminders CLI."""

    VERSION = 1

    async def async_step_user(
        self, user_input: dict[str, Any] | None = None
    ) -> FlowResult:
        """Handle the initial step."""
        errors: dict[str, str] = {}

        if user_input is not None:
            # Validate the connection
            api_client = RemindersAPIClient(
                self.hass,
                user_input[CONF_URL],
                user_input.get(CONF_TOKEN),
            )

            if await api_client.test_connection():
                # Check if already configured
                await self.async_set_unique_id(user_input[CONF_URL])
                self._abort_if_unique_id_configured()

                # Create the config entry
                return self.async_create_entry(
                    title=user_input.get(CONF_NAME, DEFAULT_NAME),
                    data=user_input,
                )
            else:
                errors["base"] = "cannot_connect"

        # Show the form
        data_schema = vol.Schema(
            {
                vol.Optional(CONF_NAME, default=DEFAULT_NAME): cv.string,
                vol.Required(CONF_URL): cv.string,
                vol.Optional(CONF_TOKEN): cv.string,
            }
        )

        return self.async_show_form(
            step_id="user",
            data_schema=data_schema,
            errors=errors,
        )
