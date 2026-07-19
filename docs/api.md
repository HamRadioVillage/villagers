# Villagers JSON API

## Versioning

All API paths are versioned under `/api/v1/`. Breaking changes will ship as a
new version prefix (`/api/v2/`); existing versions keep working until formally
deprecated. Additive changes (new endpoints, new response fields) may appear
within a version.

## Authentication

The API accepts either of:

- **Personal API token** (recommended for scripts and integrations). Create one
  under **Profile → API Tokens** in the web UI; the plaintext token (prefixed
  `vlg_`) is shown exactly once. Send it as a header:

  ```
  Authorization: Bearer vlg_your_token_here
  ```

  Tokens can be revoked at any time from the same page. Only a digest of the
  token is stored server-side.

- **Session cookie** — a signed-in browser session works for same-origin
  requests (all current endpoints are read-only GETs).

Unauthenticated requests receive `401 {"error": "unauthorized"}`.

## Errors

| Status | Body | Meaning |
|--------|------|---------|
| 401 | `{"error": "unauthorized"}` | Missing, invalid, or revoked credentials |
| 403 | `{"error": "forbidden"}` | Authenticated, but not allowed to see the requested data |
| 404 | `{"error": "not_found"}` | Unknown conference (or other resource) |
| 400 | `{"error": "invalid_date"}` | Unparseable `from`/`to` parameter |

## Access rules

Any authenticated user may call the volunteer endpoints, but the rows returned
are scoped: regular volunteers only ever see their own data, while conference
leads/admins and village admins see every volunteer at that conference and may
use the `user_id` filter freely. A regular volunteer passing someone else's
`user_id` gets a `403`.

## Endpoints

### GET /api/v1/conferences/:conference_id/volunteer_hours

Per-volunteer signed-up totals for a conference. Each signup is one 15-minute
timeslot, so `total_hours = shift_count × 0.25`.

Query parameters:

| Param | Description |
|-------|-------------|
| `user_id` | Only this volunteer's totals |

```
curl -H "Authorization: Bearer vlg_..." \
  https://example.org/api/v1/conferences/1/volunteer_hours
```

```json
{
  "conference_id": 1,
  "volunteers": [
    { "user_id": 5, "name": "Ada Lovelace", "handle": "ada", "shift_count": 12, "total_hours": 3.0 }
  ]
}
```

Volunteers are sorted by `shift_count` descending. Users with no signups at the
conference are omitted.

### GET /api/v1/conferences/:conference_id/volunteer_signups

Shift-level detail, ordered by start time.

Query parameters:

| Param | Description |
|-------|-------------|
| `user_id` | Only this volunteer's shifts |
| `program_id` | Only shifts for this program |
| `from` | ISO 8601 timestamp; shifts starting at or after this time |
| `to` | ISO 8601 timestamp; shifts starting at or before this time |

```
curl -H "Authorization: Bearer vlg_..." \
  "https://example.org/api/v1/conferences/1/volunteer_signups?user_id=5&from=2026-08-07T09:00:00Z"
```

```json
{
  "conference_id": 1,
  "signups": [
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

## Future surfaces

The `/api/v1/` namespace is the foundation for the rest of the app's API
(conferences, programs, signup creation, etc.); new endpoints will be
documented here as they land.
