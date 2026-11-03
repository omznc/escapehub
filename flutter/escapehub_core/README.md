# escapehub_core

Shared code for the EscapeHub desktop and mobile applications:

- Typed models for the API DTOs.
- The API client (`dio`) with typed errors.
- The session, the unread notification count and the reference data providers (`flutter_riverpod`).
- Form validators and a small set of shared widgets.

The API address comes from `--dart-define=API_BASE_URL=<url>`. The default is `http://localhost:5000`.
