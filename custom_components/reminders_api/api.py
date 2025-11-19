"""API client for Reminders CLI integration."""
from __future__ import annotations

import logging
from datetime import datetime
import json
from typing import Any
from urllib.parse import quote

import aiohttp
from homeassistant.core import HomeAssistant
from homeassistant.helpers.aiohttp_client import async_get_clientsession

from .const import (
    ENDPOINT_COMPLETE_REMINDER,
    ENDPOINT_CREATE_REMINDER,
    ENDPOINT_DELETE_REMINDER,
    ENDPOINT_LIST_REMINDERS,
    ENDPOINT_LISTS,
    ENDPOINT_UNCOMPLETE_REMINDER,
    ENDPOINT_UPDATE_REMINDER,
    ENDPOINT_WEBHOOKS,
)

_LOGGER = logging.getLogger(__name__)

# API request timeout (30 seconds)
API_TIMEOUT = 30


class RemindersAPIClient:
    """Client to interact with Reminders API."""

    def __init__(
        self,
        hass: HomeAssistant,
        url: str,
        token: str | None = None,
    ) -> None:
        """Initialize the API client."""
        self.hass = hass
        self.url = url.rstrip("/")
        self.token = token
        self._session = async_get_clientsession(hass)

    def _get_headers(self) -> dict[str, str]:
        """Get headers for API requests."""
        headers = {"Content-Type": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        return headers

    async def _request(
        self,
        method: str,
        endpoint: str,
        **kwargs,
    ) -> Any:
        """Make an API request."""
        url = f"{self.url}{endpoint}"
        headers = self._get_headers()
        timeout = aiohttp.ClientTimeout(total=API_TIMEOUT)

        try:
            async with self._session.request(
                method,
                url,
                headers=headers,
                timeout=timeout,
                **kwargs,
            ) as response:
                response.raise_for_status()
                if response.status == 204:  # No Content
                    return None

                text = await response.text()
                if not text.strip():
                    return None

                content_type = response.headers.get("Content-Type", "")
                if "application/json" in content_type.lower():
                    try:
                        return json.loads(text)
                    except json.JSONDecodeError as err:
                        _LOGGER.error(
                            "Failed to decode JSON response for %s %s: %s", method, url, err
                        )
                        raise

                return text
        except aiohttp.ClientError as err:
            _LOGGER.error("API request failed: %s %s - %s", method, url, err)
            raise

    async def test_connection(self) -> bool:
        """Test the connection to the API server."""
        try:
            await self._request("GET", ENDPOINT_LISTS)
            return True
        except Exception as err:  # pylint: disable=broad-except
            _LOGGER.error("Connection test failed: %s", err)
            return False

    async def get_lists(self) -> list[dict[str, Any]]:
        """Get all reminder lists with metadata."""
        return await self._request("GET", ENDPOINT_LISTS)

    async def get_reminders(self, list_name: str, include_completed: bool = False) -> list[dict[str, Any]]:
        """Get reminders from a specific list."""
        endpoint = ENDPOINT_LIST_REMINDERS.format(list_name=quote(list_name, safe=""))
        if include_completed:
            endpoint += "?completed=true"
        return await self._request("GET", endpoint)

    async def create_reminder(
        self,
        list_name: str,
        title: str,
        notes: str | None = None,
        due_date: datetime | None = None,
        priority: str | None = None,
    ) -> dict[str, Any]:
        """Create a new reminder."""
        endpoint = ENDPOINT_CREATE_REMINDER.format(list_name=quote(list_name, safe=""))
        data: dict[str, Any] = {"title": title}

        if notes:
            data["notes"] = notes
        if due_date:
            data["dueDate"] = due_date.isoformat()
        if priority:
            data["priority"] = priority

        return await self._request("POST", endpoint, json=data)

    async def update_reminder(
        self,
        list_name: str,
        reminder_id: str,
        title: str | None = None,
        notes: str | None = None,
        due_date: datetime | None = None,
        priority: str | None = None,
    ) -> dict[str, Any]:
        """Update an existing reminder."""
        endpoint = ENDPOINT_UPDATE_REMINDER.format(
            list_name=quote(list_name, safe=""),
            reminder_id=quote(reminder_id, safe=""),
        )
        data: dict[str, Any] = {}

        if title is not None:
            data["title"] = title
        if notes is not None:
            data["notes"] = notes
        if due_date is not None:
            data["dueDate"] = due_date.isoformat()
        if priority is not None:
            data["priority"] = priority

        return await self._request("PATCH", endpoint, json=data)

    async def delete_reminder(self, list_name: str, reminder_id: str) -> None:
        """Delete a reminder."""
        endpoint = ENDPOINT_DELETE_REMINDER.format(
            list_name=quote(list_name, safe=""),
            reminder_id=quote(reminder_id, safe=""),
        )
        await self._request("DELETE", endpoint)

    async def complete_reminder(self, list_name: str, reminder_id: str) -> None:
        """Mark a reminder as complete."""
        endpoint = ENDPOINT_COMPLETE_REMINDER.format(
            list_name=quote(list_name, safe=""),
            reminder_id=quote(reminder_id, safe=""),
        )
        await self._request("PATCH", endpoint)

    async def uncomplete_reminder(self, list_name: str, reminder_id: str) -> None:
        """Mark a reminder as incomplete."""
        endpoint = ENDPOINT_UNCOMPLETE_REMINDER.format(
            list_name=quote(list_name, safe=""),
            reminder_id=quote(reminder_id, safe=""),
        )
        await self._request("PATCH", endpoint)

    async def register_webhook(
        self,
        webhook_url: str,
        name: str,
        list_names: list[str] | None = None,
    ) -> dict[str, Any]:
        """Register a webhook for notifications."""
        data: dict[str, Any] = {
            "url": webhook_url,
            "name": name,
        }

        if list_names:
            data["filter"] = {
                "listNames": list_names,
                "completed": "all",
            }

        return await self._request("POST", ENDPOINT_WEBHOOKS, json=data)

    async def delete_webhook(self, webhook_id: str) -> None:
        """Delete a webhook."""
        endpoint = f"{ENDPOINT_WEBHOOKS}/{webhook_id}"
        await self._request("DELETE", endpoint)
