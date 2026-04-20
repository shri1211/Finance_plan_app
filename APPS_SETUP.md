# Local Setup & Run Flow

This guide is the standard local workflow for running the Finance Tracker backend and Flutter app together.

## 1) Install dependencies

From project root:

```bash
melos run get
```

Backend dependencies:

```bash
npm --prefix backend install
```

## 2) Start backend API

```bash
npm --prefix backend run dev
```

The backend listens on `http://localhost:3000`.

## 3) Verify backend health

Use the health endpoint exposed by the server:

```bash
curl http://localhost:3000/health
```

Expected result: JSON with `status: "ok"`.

## 4) Run Flutter app

From project root:

```bash
flutter run --flavor dev -t apps/mobile_app/lib/main_dev.dart
```

You can also use:

```bash
flutter run --flavor staging -t apps/mobile_app/lib/main_staging.dart
flutter run --flavor prod -t apps/mobile_app/lib/main_prod.dart
```

## 5) API base URL behavior

Current app setup uses `http://localhost:3000/api` by default.

If you test on Android emulator and cannot reach localhost, use one of these:

1. Port reverse:

```bash
adb reverse tcp:3000 tcp:3000
```

2. Or update app API base URL to:
`http://10.0.2.2:3000/api`

For physical devices, use your machine IP:
`http://<YOUR_MACHINE_IP>:3000/api`

## 6) Quick connectivity checks

Health:

```bash
curl http://localhost:3000/health
```

Auth route reachability:

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}'
```

## Common timeout troubleshooting

- Confirm backend process is running (`npm --prefix backend run dev`)
- Verify health endpoint (`/health`, not `/api/health`)
- Ensure emulator/device can route to backend host
- Check firewall/port access for `3000`
