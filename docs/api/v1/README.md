# API v1

See the [API overview](../README.md) for versioning, authentication, errors,
and access rules that apply to every endpoint.

## Endpoints

| Endpoint | Description |
|----------|-------------|
| [`GET /api/v1/conferences/:conference_id/volunteers`](volunteers.md) | Per-volunteer signed-up totals for a conference |
| [`GET /api/v1/conferences/:conference_id/shifts`](shifts.md) | Shift-level detail for a conference |

The `/api/v1/` namespace is the foundation for the rest of the app's API
(conferences, programs, signup creation, etc.); new endpoints will be
documented here as they land.
