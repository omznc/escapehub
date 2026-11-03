# EscapeHub mobile

The client application of EscapeHub. Only users with the Client role can sign in.

## Run

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

## Build

```sh
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

The APK is in `build/app/outputs/flutter-apk/app-release.apk`.

## Test account

| Username | Password |
| --- | --- |
| mobile | test |
