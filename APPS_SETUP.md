# Mobile App Setup Guide

## Connection Timeout Error - Quick Fix

If you see this error:
```
DioException [connection timeout]: The request connection took longer than 0:00:15.000000
```

### Step 1: Start the Backend Server

**IMPORTANT:** The backend server must be running before the mobile app can connect.

```bash
cd /Users/shreenidhi/StudioProjects/Finance_plan_app/backend
npm install  # if not already installed
npm run dev  # or npm start
```

Verify backend is running:
```bash
curl http://localhost:3000/api/health
```

### Step 2: Configure the Correct IP Address

The `ApiClient` now automatically selects the correct IP based on platform:

| Platform | URL Used |
|----------|----------|
| Android Emulator | `http://10.0.2.2:3000/api` |
| iOS Simulator | `http://localhost:3000/api` |
| Physical Device | Use your computer's actual IP (e.g., `http://192.168.1.x:3000/api`) |

### Step 3: For Physical Device Testing

If testing on a physical device, update the base URL:

**Option A: Pass URL to ApiClient constructor**
```dart
final apiClient = ApiClient(baseUrl: 'http://YOUR_MACHINE_IP:3000/api');
```

**Option B: Update at runtime**
```dart
apiClient.setBaseUrl('http://YOUR_MACHINE_IP:3000/api');
```

To find your machine's IP:
- **macOS/Linux:** `ifconfig` or `ip addr`
- **Windows:** `ipconfig`

### Step 4: Common Issues

1. **Firewall blocking port 3000**
   - macOS: `sudo ufw allow 3000` or System Preferences > Security > Firewall
   - Windows: Windows Defender Firewall settings

2. **Backend not running**
   - Check: `curl http://localhost:3000/api/health`
   - Start: `cd backend && npm run dev`

3. **Wrong IP for Android Emulator**
   - Use `10.0.2.2` NOT `localhost`

4. **CORS errors**
   - Backend should have CORS enabled (check `backend/src/index.js`)

## Updated ApiClient Features

The `ApiClient` has been enhanced with:

- ✅ **Automatic platform detection** for default base URL
- ✅ **Extended timeout** (30 seconds instead of 15)
- ✅ **Better error messages** with troubleshooting hints
- ✅ **Runtime URL switching** via `setBaseUrl()`
- ✅ **Three timeout types**: connect, receive, and send

## Testing Connection

```bash
# Test from terminal
curl http://localhost:3000/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}'
```
