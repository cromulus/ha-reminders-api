"""The Reminders CLI integration."""
from __future__ import annotations

import logging
from datetime import timedelta

from homeassistant.config_entries import ConfigEntry
from homeassistant.const import CONF_URL, Platform
from homeassistant.core import HomeAssistant
from homeassistant.helpers.update_coordinator import DataUpdateCoordinator, UpdateFailed

from .api import RemindersAPIClient
from .const import CONF_NAME, CONF_TOKEN, DOMAIN, UPDATE_INTERVAL

_LOGGER = logging.getLogger(__name__)

PLATFORMS: list[Platform] = [Platform.TODO]


async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Set up Reminders CLI from a config entry."""
    # Create API client
    api_client = RemindersAPIClient(
        hass,
        entry.data[CONF_URL],
        entry.data.get(CONF_TOKEN),
    )

    # Create data update coordinator
    coordinator = RemindersDataUpdateCoordinator(hass, api_client, entry)

    # Fetch initial data
    await coordinator.async_config_entry_first_refresh()

    # Store coordinator
    hass.data.setdefault(DOMAIN, {})
    hass.data[DOMAIN][entry.entry_id] = coordinator

    # Set up platforms
    await hass.config_entries.async_forward_entry_setups(entry, PLATFORMS)

    return True


async def async_unload_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Unload a config entry."""
    # Unload platforms
    if unload_ok := await hass.config_entries.async_unload_platforms(entry, PLATFORMS):
        coordinator = hass.data[DOMAIN].pop(entry.entry_id)
        # Cleanup webhooks if any
        if hasattr(coordinator, "webhook_id") and coordinator.webhook_id:
            try:
                await coordinator.api.delete_webhook(coordinator.webhook_id)
            except Exception as err:  # pylint: disable=broad-except
                _LOGGER.warning("Failed to delete webhook: %s", err)

    return unload_ok


class RemindersDataUpdateCoordinator(DataUpdateCoordinator):
    """Class to manage fetching Reminders data."""

    def __init__(
        self,
        hass: HomeAssistant,
        api: RemindersAPIClient,
        entry: ConfigEntry,
    ) -> None:
        """Initialize the coordinator."""
        self.api = api
        self.entry = entry
        self.webhook_id: str | None = None
        self.lists_data: dict[str, list[dict]] = {}
        self.lists_meta: dict[str, dict] = {}

        super().__init__(
            hass,
            _LOGGER,
            name=DOMAIN,
            update_interval=timedelta(seconds=UPDATE_INTERVAL),
        )

    async def _async_update_data(self) -> dict[str, list[dict]]:
        """Fetch data from API."""
        try:
            # Get all lists with metadata
            raw_lists = await self.api.get_lists()

            lists_meta: dict[str, dict] = {}
            lists_data: dict[str, list[dict]] = {}

            for list_info in raw_lists:
                list_id = list_info.get("uuid") or list_info.get("id")
                if not list_id:
                    _LOGGER.warning("Skipping list without UUID: %s", list_info)
                    continue

                lists_meta[list_id] = list_info

                try:
                    reminders = await self.api.get_reminders(
                        list_id, include_completed=True
                    )
                    lists_data[list_id] = reminders or []
                except Exception as err:  # pylint: disable=broad-except
                    display_name = list_info.get("title", list_id)
                    _LOGGER.error(
                        "Error fetching reminders for %s (%s): %s",
                        display_name,
                        list_id,
                        err,
                    )
                    lists_data[list_id] = []

            self.lists_meta = lists_meta
            self.lists_data = lists_data
            return lists_data

        except Exception as err:
            _LOGGER.error("Error fetching data: %s", err)
            raise UpdateFailed(f"Error communicating with API: {err}") from err

    async def async_refresh_list(self, list_id: str) -> None:
        """Refresh data for a specific list."""
        try:
            reminders = await self.api.get_reminders(list_id, include_completed=True)
            self.lists_data[list_id] = reminders or []
            self.async_set_updated_data(self.lists_data)
        except Exception as err:  # pylint: disable=broad-except
            display_name = self.lists_meta.get(list_id, {}).get("title", list_id)
            _LOGGER.error("Error refreshing list %s (%s): %s", display_name, list_id, err)
