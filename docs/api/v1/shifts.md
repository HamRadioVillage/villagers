# GET /api/v1/conferences/:conference_id/shifts

Shift-level detail for a conference, ordered by start time. Each shift is one
15-minute timeslot signup.

## Access

Regular volunteers see only their own shifts; conference leads/admins and
village admins see everyone's. See [access rules](../README.md#access-rules).

## Query parameters

| Param | Description |
|-------|-------------|
| `user_id` | Only this volunteer's shifts |
| `program_id` | Only shifts for this program |
| `from` | ISO 8601 timestamp; shifts starting at or after this time |
| `to` | ISO 8601 timestamp; shifts starting at or before this time |

## Example

```
curl -H "Authorization: Bearer vlg_..." \
  "https://example.org/api/v1/conferences/1/shifts?user_id=5&from=2026-08-07T09:00:00Z"
```

```json
{
  "conference_id": 1,
  "shifts": [
    {
      "id": 42,
      "user_id": 5,
      "program": "Ham Exams",
      "starts_at": "2026-08-07T09:00:00Z",
      "ends_at": "2026-08-07T09:15:00Z"
    }
  ]
}
```

## Response fields

| Field | Description |
|-------|-------------|
| `id` | Signup id |
| `user_id` | The volunteer's user id |
| `program` | Program name |
| `starts_at` | Shift start (RFC 3339, UTC) |
| `ends_at` | Shift end (RFC 3339, UTC) |

## Errors

`400` unparseable `from`/`to` · `401` unauthenticated · `403` non-manager
requesting another `user_id` · `404` unknown conference.
See [errors](../README.md#errors).
