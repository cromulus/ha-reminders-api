"""Todo platform for Reminders CLI integration."""
from __future__ import annotations

import logging
from datetime import datetime
from typing import Any

from homeassistant.components.todo import (
    TodoItem,
    TodoItemStatus,
    TodoListEntity,
    TodoListEntityFeature,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant, callback
from homeassistant.exceptions import HomeAssistantError
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from . import RemindersDataUpdateCoordinator
from .const import DOMAIN

_LOGGER = logging.getLogger(__name__)


async def async_setup_entry(
    hass: HomeAssistant,
    entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up the Reminders CLI todo platform."""
    coordinator: RemindersDataUpdateCoordinator = hass.data[DOMAIN][entry.entry_id]
    known_ids: set[str] = set()

    @callback
    def _sync_entities() -> None:
        new_entities: list[RemindersTodoListEntity] = []
        for list_id in coordinator.lists_data:
            if list_id in known_ids:
                continue
            new_entities.append(RemindersTodoListEntity(coordinator, list_id))
            known_ids.add(list_id)

        if new_entities:
            async_add_entities(new_entities)

    _sync_entities()
    entry.async_on_unload(coordinator.async_add_listener(_sync_entities))


class RemindersTodoListEntity(CoordinatorEntity[RemindersDataUpdateCoordinator], TodoListEntity):
    """A To-do List representation of a Reminders list."""

    _attr_has_entity_name = True
    _attr_supported_features = (
        TodoListEntityFeature.CREATE_TODO_ITEM
        | TodoListEntityFeature.DELETE_TODO_ITEM
        | TodoListEntityFeature.UPDATE_TODO_ITEM
        | TodoListEntityFeature.SET_DUE_DATETIME_ON_ITEM
        | TodoListEntityFeature.SET_DESCRIPTION_ON_ITEM
    )

    def __init__(
        self,
        coordinator: RemindersDataUpdateCoordinator,
        list_id: str,
    ) -> None:
        """Initialize the todo list entity."""
        super().__init__(coordinator)
        self.list_id = list_id
        self._attr_unique_id = f"{coordinator.entry.entry_id}_{list_id}"
        self._attr_name = self._display_name

    @property
    def _metadata(self) -> dict[str, Any]:
        """Return metadata for this reminders list."""
        return self.coordinator.lists_meta.get(self.list_id, {})

    @property
    def _display_name(self) -> str:
        """Return the display name for this list."""
        return self._metadata.get("title") or self.list_id

    @property
    def name(self) -> str | None:
        """Return the current list name."""
        return self._display_name

    @property
    def device_info(self):
        """Return device info for grouping entities."""
        return {
            "identifiers": {(DOMAIN, self.coordinator.entry.entry_id)},
            "name": "Reminders CLI",
            "manufacturer": "Apple",
            "model": "macOS Reminders",
            "entry_type": "service",
        }

    @property
    def available(self) -> bool:
        """Return True if entity is available."""
        return self.coordinator.last_update_success

    @property
    def todo_items(self) -> list[TodoItem] | None:
        """Return the todo items."""
        reminders = self.coordinator.lists_data.get(self.list_id, [])

        return [
            TodoItem(
                uid=uid,
                summary=reminder.get("title", ""),
                status=TodoItemStatus.COMPLETED
                if reminder.get("isCompleted", False)
                else TodoItemStatus.NEEDS_ACTION,
                due=self._parse_due_date(reminder.get("dueDate")),
                description=reminder.get("notes"),
            )
            for reminder in reminders
            if (uid := self._reminder_uid(reminder))
        ]

    def _parse_due_date(self, due_date_str: str | None) -> datetime | None:
        """Parse due date string to datetime."""
        if not due_date_str:
            return None
        try:
            return datetime.fromisoformat(due_date_str.replace("Z", "+00:00"))
        except (ValueError, AttributeError):
            _LOGGER.warning("Failed to parse due date: %s", due_date_str)
            return None

    async def async_create_todo_item(self, item: TodoItem) -> None:
        """Create a new todo item."""
        try:
            await self.coordinator.api.create_reminder(
                list_name=self.list_id,
                title=item.summary,
                notes=item.description,
                due_date=item.due,
            )
            await self.coordinator.async_refresh_list(self.list_id)
        except Exception as err:
            raise HomeAssistantError(f"Failed to create reminder: {err}") from err

    async def async_update_todo_item(self, item: TodoItem) -> None:
        """Update a todo item."""
        try:
            reminder_id = self._extract_reminder_id(item.uid)
            reminders = self.coordinator.lists_data.get(self.list_id, [])
            current_reminder = next(
                (
                    r
                    for r in reminders
                    if self._extract_reminder_id(self._reminder_uid(r)) == reminder_id
                ),
                None,
            )

            if not current_reminder:
                raise HomeAssistantError(
                    f"Reminder {item.uid} not found in list {self._display_name}"
                )

            # Check if completion status changed
            is_completed = item.status == TodoItemStatus.COMPLETED
            was_completed = current_reminder.get("isCompleted", False)

            # Check if non-status fields changed
            current_due = self._parse_due_date(current_reminder.get("dueDate"))
            title_changed = item.summary != current_reminder.get("title")
            notes_changed = item.description != current_reminder.get("notes")
            due_changed = item.due != current_due

            # If only status changed, use complete/uncomplete endpoints
            if is_completed != was_completed and not (title_changed or notes_changed or due_changed):
                if is_completed:
                    await self.coordinator.api.complete_reminder(
                        self.list_id, reminder_id
                    )
                else:
                    await self.coordinator.api.uncomplete_reminder(
                        self.list_id, reminder_id
                    )
            else:
                # Update all fields (including status via isCompleted in the update)
                # Note: The update endpoint doesn't support isCompleted, so we still need
                # to call complete/uncomplete if status changed
                if is_completed != was_completed:
                    if is_completed:
                        await self.coordinator.api.complete_reminder(
                            self.list_id, reminder_id
                        )
                    else:
                        await self.coordinator.api.uncomplete_reminder(
                            self.list_id, reminder_id
                        )

                # Only call update if non-status fields changed
                if title_changed or notes_changed or due_changed:
                    await self.coordinator.api.update_reminder(
                        list_name=self.list_id,
                        reminder_id=reminder_id,
                        title=item.summary if title_changed else None,
                        notes=item.description if notes_changed else None,
                        due_date=item.due if due_changed else None,
                    )

            await self.coordinator.async_refresh_list(self.list_id)
        except Exception as err:
            raise HomeAssistantError(f"Failed to update reminder: {err}") from err

    async def async_delete_todo_items(self, uids: list[str]) -> None:
        """Delete todo items."""
        try:
            for uid in uids:
                reminder_id = self._extract_reminder_id(uid)
                await self.coordinator.api.delete_reminder(self.list_id, reminder_id)

            await self.coordinator.async_refresh_list(self.list_id)
        except Exception as err:
            raise HomeAssistantError(f"Failed to delete reminders: {err}") from err

    def _reminder_uid(self, reminder: dict[str, Any]) -> str | None:
        """Return the external identifier for a reminder."""
        uid = reminder.get("externalId") or reminder.get("uuid") or reminder.get("id")
        if isinstance(uid, str):
            return uid
        return None

    def _extract_reminder_id(self, uid: str | None) -> str:
        """Extract reminder ID from UID."""
        if not uid:
            raise HomeAssistantError("Reminder identifier is missing")

        # Handle IDs prefixed with the x-apple scheme
        if uid.startswith("x-apple-reminder://"):
            return uid.replace("x-apple-reminder://", "")
        return uid
