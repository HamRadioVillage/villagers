# Villagers JSON API

## Versioning

All API paths are versioned under `/api/v1/`. Breaking changes will ship as a
new version prefix (`/api/v2/`); existing versions keep working until formally
deprecated. Additive changes (new endpoints, new response fields) may appear
within a version.

Endpoint documentation lives in a directory per version:

- [v1 endpoints](v1/README.md)

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
