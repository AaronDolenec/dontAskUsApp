# Additional API Endpoints and Behavior

This document outlines the new endpoints introduced to support notification preferences,
user display names, and other settings. Backend implementations are required to match
these contracts.

## Group Display Name

- **POST /api/auth/groups/create**
  - Request body can now include `display_name` (string) which will be used as the
    creator's display name for the group. Example:
    ```json
    { "name": "My Group", "display_name": "Alice" }
    ```

- **PUT /api/auth/groups/{groupId}/display-name**
  - Update the current user's display name within the specified group.
  - Body:
    ```json
    { "display_name": "Bob" }
    ```

## Notification Settings

- **GET /api/users/{userId}/notification-settings**
  - Returns the current notification preferences for the user. Sample response:
    ```json
    {
      "push_enabled": true,
      "email_enabled": false,
      "push_for_all_groups": false
    }
    ```

- **PUT /api/users/{userId}/notification-settings**
  - Update the notification preferences. Accepts the same structure as the GET response.

- **POST /api/groups/{groupId}/notifications** (optional)
  - (Proposed) set notification preferences scoped to one group. This may be used
    by clients that prefer per-group endpoints.

## Push Notifications & Email Notifications

Users may now decide which channels they receive notifications on. Preferences can
be global or per-group; the endpoints above support both modes. When `push_for_all_groups`
is enabled the server should automatically register a device token for every group
the user is a member of.

## API Documentation Notes

- Documented environment variables are unchanged but new ones may be added for
  push notification service account keys, etc.
- The clients (web/mobile) should call the new endpoints when appropriate.

The above endpoints are speculative and must be implemented by the backend team.
They correspond to UI changes made in the Flutter client (`NotificationSettingsScreen`).