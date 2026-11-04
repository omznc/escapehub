# EscapeHub

Seminar project for Razvoj softvera II. A booking system for an escape room business: ASP.NET Core 8 API, a RabbitMQ worker, a Flutter desktop app for staff and a Flutter mobile app for clients.

## Setup

You need Docker (or Podman), the .NET 8 SDK and Flutter 3.47.

The `.env` file is in `.env-tajne.zip` (password is on DL). Extract it in the root folder, next to `docker-compose.yml`:

```sh
unzip .env-tajne.zip
docker compose up -d --build
```

This starts SQL Server, RabbitMQ, Mailpit, the API and the worker. Migrations and seed data run on API startup, so the first start takes a minute or two.

- API: http://localhost:5000 (Swagger at `/swagger`)
- RabbitMQ UI: http://localhost:15672
- Mailpit (all sent emails): http://localhost:8025

`docker compose down -v` resets the database.

## Flutter apps

Run `flutter pub get` first in each app folder.

Desktop:

```sh
cd flutter/escapehub_desktop
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5000
```

Mobile (Android emulator):

```sh
cd flutter/escapehub_mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

On a physical phone use your computer's IP instead of `10.0.2.2`. Pass `API_BASE_URL` to release builds too (`flutter build windows --release` / `flutter build apk --release`).

## Credentials

| Kontekst | Korisničko ime | Lozinka |
| --- | --- | --- |
| Desktop verzija | desktop | test |
| Mobilna verzija | mobile | test |
| Administrator | administrator | test |
| RoomManager | roommanager | test |
| Client | client | test |

There are a few more seeded accounts, all with password `test`:

- Administrator: `zavala`
- RoomManager: `ikora`, `eris`
- Client: `cayde6`, `alanwake`, `sagaanderson`, `drifter`, `osiris`, `saint14`, `tor`

The desktop app only accepts staff accounts and the mobile app only accepts clients.

## Payments

Payments in the mobile app run in the Polar.sh sandbox, so no real money moves. A client can pay a booking after the staff confirm it. Use the test card `4242 4242 4242 4242` with any future date and any CVC. When staff cancel a paid booking, the API refunds the paid amount through Polar.

## Other

- Recommender: [recommender-dokumentacija.md](recommender-dokumentacija.md)
- Image sources and licenses: [CREDITS.md](src/EscapeHub.Infrastructure/Seed/Images/CREDITS.md)
