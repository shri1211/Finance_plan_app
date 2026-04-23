# mobile_app

Flutter client for the Finance Tracker app.

## Prerequisites

- Flutter SDK
- Running backend API on `http://localhost:3000`

## Run commands

From repository root:

```bash
flutter run --flavor dev -t apps/mobile_app/lib/main_dev.dart
```

Other flavors:

```bash
flutter run --flavor staging -t apps/mobile_app/lib/main_staging.dart
flutter run --flavor prod -t apps/mobile_app/lib/main_prod.dart
```

## Backend connectivity

The app currently uses `http://localhost:3000/api` by default.

If Android emulator cannot reach localhost:

```bash
adb reverse tcp:3000 tcp:3000
```

Or set API base URL to `http://10.0.2.2:3000/api`.

For physical devices, use your machine IP:
`http://<YOUR_MACHINE_IP>:3000/api`
