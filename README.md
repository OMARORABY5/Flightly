# FLIGHTLY

A comprehensive, microservices-backed flight booking mobile application built with Flutter and Node.js.

## Architecture

**Frontend (Mobile App)**
- **Framework:** Flutter 3.41.7
- **Language:** Dart
- **State Management:** Riverpod
- **Routing:** GoRouter
- **Network:** Dio
- **Architecture:** Feature-based clean architecture

**Backend (Microservices)**
- **Runtime:** Node.js v24.11.1
- **Framework:** Express.js
- **API Gateway:** NGINX (Port 80)
- **Services:**
  - Auth Service (Port 3001)
  - Flight Service (Port 3002)
  - Booking Service (Port 3003)
  - User Service (Port 3004)
  - Notification Service (Port 3005)

**Infrastructure (Docker)**
- **Primary Database:** PostgreSQL 15 (Port 5432)
- **Cache & Sessions:** Redis 7 (Port 6379)
- **Orchestration:** Docker Compose

## Getting Started

### Prerequisites
- Docker & Docker Compose
- Flutter SDK (^3.11.5)
- Node.js (for backend local development)

### Running the Backend
Ensure Docker Desktop is running, then execute from the root directory:
```bash
docker-compose up -d
```
This will start PostgreSQL, Redis, all 5 microservices, and the NGINX gateway.
You can verify the services are running by accessing the health endpoints:
- `http://localhost/health/auth`
- `http://localhost/health/flights`
- `http://localhost/health/bookings`
- `http://localhost/health/users`
- `http://localhost/health/notifications`

### Running the Mobile App
Navigate to the `mobile` directory, fetch dependencies, and run:
```bash
cd mobile
flutter pub get
flutter run
```

## Project Phases

This project is built incrementally in 13 phases. Currently **Phase 3 (Flight Search Flow)** is completed. Please refer to `CLAUDE.md` and `task.md` for detailed progression and architecture plans.
