# Flightly Project Transfer Guide

Follow these steps to set up the project on your other laptop.

## 1. Prerequisites
Ensure the following are installed:
- **Git**
- **Docker & Docker Compose**
- **Flutter SDK**
- **VS Code** (with Flutter/Dart extensions)

## 2. Get the Code
Open a terminal on your new machine and run:
```powershell
git clone https://github.com/OMARORABY5/Flightly.git
cd Flightly
```

## 3. Set Up the Backend
Start the Docker containers (PostgreSQL, Redis, and Services):
```powershell
docker-compose up -d
```
*Wait a minute for the database to initialize.*

## 4. Restore the Database
To restore the latest data from the backup:
```powershell
# Restore the backup into the running postgres container
# In PowerShell:
Get-Content flightly_backup.sql | docker exec -i flightly-postgres psql -U flightly_user -d flightly
```

## 5. Set Up the Mobile App
Go to the mobile directory and get dependencies:
```powershell
cd mobile
flutter pub get
```

## 6. Run the Project
You can now run the app on Chrome (or your emulator):
```powershell
flutter run -d chrome
```

---
**Note:** Since you have the absolute path to Flutter and Git mapped differently on each machine, remember to update your environment variables (PATH) on the new machine so you can run `flutter` and `git` commands directly without full paths.
