# GET /api/v1/conferences/:conference_id/volunteers

Per-volunteer signed-up totals for a conference. Each signup is one 15-minute
timeslot, so `total_hours = shift_count × 0.25`.

Volunteers are sorted by `shift_count` descending. Users with no signups at the
conference are omitted.

## Access

Regular volunteers see only their own entry; conference leads/admins and
village admins see every volunteer. See [access rules](../README.md#access-rules).

## Query parameters

| Param | Description |
|-------|-------------|
| `user_id` | Only this volunteer's totals |

## Example

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

## Response fields

| Field | Description |
|-------|-------------|
| `user_id` | The volunteer's user id |
| `name` | Display name |
| `handle` | Handle, if set |
| `shift_count` | Number of 15-minute timeslots signed up for |
| `total_hours` | `shift_count × 0.25` |

## Errors

`401` unauthenticated · `403` non-manager requesting another `user_id` ·
`404` unknown conference. See [errors](../README.md#errors).
