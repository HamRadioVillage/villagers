# Conferences

The conference (event) is the top-level API resource. Volunteer data is
exposed as sub-resources of a conference.

- [`GET /api/v1/conferences`](#get-apiv1conferences) — list event-level details
- [`GET /api/v1/conferences/:id`](#get-apiv1conferencesid) — one conference
- [`GET /api/v1/conferences/:conference_id/volunteers`](#get-apiv1conferencesconference_idvolunteers) — per-volunteer totals
- [`GET /api/v1/conferences/:conference_id/volunteers/:id`](#get-apiv1conferencesconference_idvolunteersid) — one volunteer's totals
- [`GET /api/v1/conferences/:conference_id/shifts`](#get-apiv1conferencesconference_idshifts) — shift-level detail
- [`GET /api/v1/conferences/:conference_id/shifts/:id`](#get-apiv1conferencesconference_idshiftsid) — one shift

## GET /api/v1/conferences

Event-level details for every conference, newest first. Available to any
authenticated user; archived conferences are included and flagged.

### Example

```
curl -H "Authorization: Bearer vlg_..." \
  https://example.org/api/v1/conferences
```

```json
{
  "conferences": [
    {
      "id": 1,
      "name": "DEF CON 34",
      "city": "Las Vegas",
      "state": "NV",
      "country": "US",
      "start_date": "2026-08-07",
      "end_date": "2026-08-09",
      "hours_start": "09:00",
      "hours_end": "17:00",
      "archived": false
    }
  ]
}
```

### Response fields

| Field | Description |
|-------|-------------|
| `id` | Conference id (use as `:conference_id` in sub-resource paths) |
| `name` | Conference name |
| `city` / `state` / `country` | Location |
| `start_date` / `end_date` | ISO 8601 dates |
| `hours_start` / `hours_end` | Daily conference hours (`HH:MM`) |
| `archived` | Whether the conference has been archived |

## GET /api/v1/conferences/:id

A single conference, same fields as the list entries above.

```
curl -H "Authorization: Bearer vlg_..." \
  https://example.org/api/v1/conferences/1
```

```json
{
  "conference": {
    "id": 1,
    "name": "DEF CON 34",
    "city": "Las Vegas",
    "state": "NV",
    "country": "US",
    "start_date": "2026-08-07",
    "end_date": "2026-08-09",
    "hours_start": "09:00",
    "hours_end": "17:00",
    "archived": false
  }
}
```

`404` for an unknown conference.

## GET /api/v1/conferences/:conference_id/volunteers

Per-volunteer signed-up totals for a conference. Each signup is one 15-minute
timeslot, so `total_hours = shift_count × 0.25`.

Volunteers are sorted by `shift_count` descending. Users with no signups at the
conference are omitted.

Regular volunteers see only their own entry; conference leads/admins and
village admins see every volunteer. See [access rules](../README.md#access-rules).

### Query parameters

| Param | Description |
|-------|-------------|
| `user_id` | Only this volunteer's totals |

### Example

```
curl -H "Authorization: Bearer vlg_..." \
  https://example.org/api/v1/conferences/1/volunteers
```

```json
{
  "conference_id": 1,
  "volunteers": [
    { "user_id": 5, "name": "Ada Lovelace", "handle": "ada", "shift_count": 12, "total_hours": 3.0 }
  ]
}
```

### Response fields

| Field | Description |
|-------|-------------|
| `user_id` | The volunteer's user id |
| `name` | Display name |
| `handle` | Handle, if set |
| `shift_count` | Number of 15-minute timeslots signed up for |
| `total_hours` | `shift_count × 0.25` |

### Errors

`401` unauthenticated · `403` non-manager requesting another `user_id` ·
`404` unknown conference. See [errors](../README.md#errors).

## GET /api/v1/conferences/:conference_id/volunteers/:id

One volunteer's totals for the conference (`:id` is the user id), same fields
as the list entries. Unlike the list, a volunteer with no signups is returned
with zero totals rather than omitted.

```
curl -H "Authorization: Bearer vlg_..." \
  https://example.org/api/v1/conferences/1/volunteers/5
```

```json
{
  "conference_id": 1,
  "volunteer": { "user_id": 5, "name": "Ada Lovelace", "handle": "ada", "shift_count": 12, "total_hours": 3.0 }
}
```

`403` for a non-manager requesting anyone but themselves · `404` for an
unknown user or conference.

## GET /api/v1/conferences/:conference_id/shifts

Shift-level detail for a conference, ordered by start time. Each shift is one
15-minute timeslot signup.

Regular volunteers see only their own shifts; conference leads/admins and
village admins see everyone's. See [access rules](../README.md#access-rules).

### Query parameters

| Param | Description |
|-------|-------------|
| `user_id` | Only this volunteer's shifts |
| `program_id` | Only shifts for this program |
| `from` | ISO 8601 timestamp; shifts starting at or after this time |
| `to` | ISO 8601 timestamp; shifts starting at or before this time |

### Example

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

### Response fields

| Field | Description |
|-------|-------------|
| `id` | Signup id |
| `user_id` | The volunteer's user id |
| `program` | Program name |
| `starts_at` | Shift start (RFC 3339, UTC) |
| `ends_at` | Shift end (RFC 3339, UTC) |

### Errors

`400` unparseable `from`/`to` · `401` unauthenticated · `403` non-manager
requesting another `user_id` · `404` unknown conference.
See [errors](../README.md#errors).

## GET /api/v1/conferences/:conference_id/shifts/:id

A single shift (`:id` is the signup id), same fields as the list entries.
Non-managers can only see their own shifts; anyone else's shift id returns
`404` (indistinguishable from a nonexistent one).

```
curl -H "Authorization: Bearer vlg_..." \
  https://example.org/api/v1/conferences/1/shifts/42
```

```json
{
  "conference_id": 1,
  "shift": {
    "id": 42,
    "user_id": 5,
    "program": "Ham Exams",
    "starts_at": "2026-08-07T09:00:00Z",
    "ends_at": "2026-08-07T09:15:00Z"
  }
}
```
