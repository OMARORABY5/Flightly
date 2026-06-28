# Flightly

## Smart Flight Booking Platform

Flightly is a smart flight booking platform designed to simplify the travel experience through a modern and intuitive mobile application. It enables users to search, compare, and book flights while providing intelligent pricing recommendations that support better travel decisions.

---

## Table of Contents

* Overview
* Key Features
* Application Preview
* Technology Stack
* System Architecture
* Project Structure
* Getting Started
* Developer

---

# Overview

Flightly integrates flight search, comparison, and booking into a single platform. Built using a microservices architecture, it provides real-time flight information, intelligent decision support, and a streamlined booking experience.

---

# Key Features

* Real-time flight search
* Multi-airline flight comparison
* Advanced flight filters
* Smart Recommendations
* Smart Pricing Insights
* Watchlist and fare alerts
* Egyptian payment methods
* Secure authentication
* Firebase push notifications
* Modern Flutter mobile application

---

# Application Preview

> Add screenshots of the application here.

Suggested screenshots:

* Home Screen
* Flight Search
* Search Results
* Flight Details
* Smart Recommendation
* Booking Confirmation

---

# Technology Stack

### Mobile

* Flutter
* Dart

### Backend

* Node.js
* Express.js
* REST APIs
* Microservices Architecture

### Infrastructure

* Docker
* NGINX API Gateway
* PostgreSQL
* Redis

### Services

* Firebase Cloud Messaging

---

# System Architecture

The backend consists of multiple independent microservices communicating through an API Gateway.

Services include:

* Authentication Service
* User Service
* Flight Service
* Booking Service
* Notification Service

---

# Project Structure

```text
Flightly/
├── mobile/
├── services/
├── nginx/
├── database/
└── docker-compose.yml
```

---

# Getting Started

Clone the repository:

```bash
git clone https://github.com/OMARORABY5/Flightly.git
cd Flightly
```

Start the backend:

```bash
docker-compose build
docker-compose up -d
```

Run the Flutter application:

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

> **Note:** The Firebase service account file is not included in this repository for security reasons.

---

# Developer

**Omar Abdelrahman Oraby**

Computer Science Student

Graduation Project 2025–2026
