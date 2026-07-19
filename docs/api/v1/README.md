# API v1

See the [API overview](../README.md) for versioning, authentication, errors,
and access rules that apply to every endpoint.

## Resources

Endpoints are documented per top-level resource:

- [Conferences](conferences.md)
  - `GET /api/v1/conferences` — event-level details
  - `GET /api/v1/conferences/:id` — one conference
  - `GET /api/v1/conferences/:conference_id/volunteers` — per-volunteer totals
  - `GET /api/v1/conferences/:conference_id/volunteers/:id` — one volunteer's totals
  - `GET /api/v1/conferences/:conference_id/shifts` — shift-level detail
  - `GET /api/v1/conferences/:conference_id/shifts/:id` — one shift

The `/api/v1/` namespace is the foundation for the rest of the app's API
(programs, signup creation, etc.); new resources will be documented here as
they land.
