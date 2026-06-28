Flightly — Share & Setup Guide

> A complete guide for running Flightly on a new PC using the GitHub repo.

---

## Project Structure

Everything lives in **one folder** — backend + frontend together:

```
Flightly/
├── mobile/            ← Flutter app
├── services/          ← All Node.js backend services
├── nginx/             ← API Gateway config
├── database/          ← SQL migrations (auto-run by Docker)
└── docker-compose.yml ← Master file that runs the entire backend
```

---

## Step 1 — Clone the Project

```bash
git clone https://github.com/OMARORABY5/Flightly.git
cd Flightly
```

---

## Step 2 — Add the Secret Firebase File

> **This file is NOT on GitHub for security reasons.**
> You must receive it manually (USB, WhatsApp, email, etc.) from the project owner.

Place this file in the **root** of the `Flightly/` folder:

```
flightly-oraby-firebase-adminsdk-fbsvc-af56f5f7ac.json
```

Without this file, push notifications will not work.

---

## Step 3 — Start the Backend (Docker)

Make sure **Docker Desktop is installed and running**, then open a terminal inside `Flightly/`:

```bash
# Build all backend images (only needed once, or after any backend code change)
docker-compose build

# Start all services in the background
docker-compose up -d
```

Wait ~30 seconds, then verify everything is running:

```bash
docker-compose ps
```

All containers should show status `Up`. You can also open your browser and visit:

| URL | Expected |
|---|---|
| `http://localhost/health` | `{"status":"healthy","service":"nginx-gateway"}` |
| `http://localhost/health/users` | `{"status":"healthy","service":"user-service",...}` |
| `http://localhost/health/auth` | `{"status":"healthy","service":"auth-service",...}` |

### Services Started by Docker

| Container | Purpose | Port |
|---|---|---|
| `flightly-nginx` | API Gateway | 80 |
| `flightly-auth` | Auth Service | 3001 |
| `flightly-flight` | Flight Service | 3002 |
| `flightly-booking` | Booking Service | 3003 |
| `flightly-user` | User Service | 3004 |
| `flightly-notification` | Notifications | 3005 |
| `flightly-postgres` | Database | 5432 |
| `flightly-redis` | Cache | 6379 |

> The database schema and seed data initialize **automatically** on first start. No manual SQL setup needed.

---

## Step 4 — Set Up the Flutter App

Open a terminal inside `Flightly/mobile/`:

```bash
flutter pub get
```

---

## Step 5 — Configure the API URL

Open this file:
```
mobile/lib/core/constants/app_constants.dart
```

Find this section and set the correct URL based on how you're running the app:

```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:80/api'; //Chrome/Web — no change needed
  }
  return 'http://10.0.2.2:80/api';    //Android Emulator — no change needed

  // Physical Android/iOS phone on same WiFi:
  // return 'http://YOUR_PC_LOCAL_IP:80/api';
  // Find your IP by running: ipconfig (Windows) or ifconfig (Mac/Linux)
}
```

---

## Step 6 — Run the App

```bash
# Web browser (easiest — no emulator needed)
flutter run -d chrome

# Android Emulator (start it from Android Studio first)
flutter run

# Physical Android phone (USB debugging must be enabled)
flutter run
```

---

## Quick Summary (3 commands to get running)

```bash
# 1. Clone
git clone https://github.com/OMARORABY5/Flightly.git && cd Flightly

# 2. Start backend
docker-compose build
docker-compose up -d

# 3. Start Flutter app
cd mobile && flutter pub get && flutter run -d chrome
```

---

## Important Notes

- **After editing any backend `.js` file**, you must rebuild:
  ```bash
  docker-compose build <service-name>
  docker-compose up -d <service-name>
  ```
  A simple `restart` does **not** pick up code changes.

- **Flutter** changes are picked up instantly with Hot Reload (`r`) or Hot Restart (`R`).

- Make sure Docker Desktop is **always running** before starting the app.
