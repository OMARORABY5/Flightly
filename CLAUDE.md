# CLAUDE.md — FLIGHTLY Project Master Reference File

> **FOR ANY AI MODEL OR AGENT READING THIS FILE:**
> This is the single source of truth for the FLIGHTLY graduation project. Every architectural
> decision, feature, phase, rule, and implementation detail is documented here. Read this file
> completely before taking any action. Do not skip any section. All instructions are mandatory
> unless explicitly marked as "future scope" or "dummy/UI-only".

---

## TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [Technology Stack Decisions](#2-technology-stack-decisions)
3. [Architecture: Microservices Explained](#3-architecture-microservices-explained)
4. [Mandatory Development Rules (Golden Rules)](#4-mandatory-development-rules-golden-rules)
5. [Stage-by-Stage Development Protocol](#5-stage-by-stage-development-protocol)
6. [Testing Rules](#6-testing-rules)
7. [Documentation Rules](#7-documentation-rules)
8. [Git & GitHub Rules](#8-git--github-rules)
9. [UI/UX & Design Rules](#9-uiux--design-rules)
10. [Security Rules](#10-security-rules)
11. [Error Handling & Learning Mode](#11-error-handling--learning-mode)
12. [Feature Checklist (All Phases)](#12-feature-checklist-all-phases)
13. [Phase 0 — Project Setup & Environment](#13-phase-0--project-setup--environment)
14. [Phase 1 — Onboarding Flow](#14-phase-1--onboarding-flow)
15. [Phase 2 — Authentication Flow](#15-phase-2--authentication-flow)
16. [Phase 3 — Flight Search Flow](#16-phase-3--flight-search-flow)
17. [Phase 4 — Flight Results, Filtering & Sorting](#17-phase-4--flight-results-filtering--sorting)
18. [Phase 5 — Flight Details & Smart Pricing](#18-phase-5--flight-details--smart-pricing)
19. [Phase 6 — Booking & Reservation Flow](#19-phase-6--booking--reservation-flow)
20. [Phase 7 — Payment Flow (Dummy Scope)](#20-phase-7--payment-flow-dummy-scope)
21. [Phase 8 — Notifications & Alerts](#21-phase-8--notifications--alerts)
22. [Phase 9 — Saved Flights / Watch Flow](#22-phase-9--saved-flights--watch-flow)
23. [Phase 10 — My Trips Flow](#23-phase-10--my-trips-flow)
24. [Phase 11 — Account & Profile Management](#24-phase-11--account--profile-management)
25. [Phase 12 — System States & Feedback Handling](#25-phase-12--system-states--feedback-handling)
26. [Phase 13 — Unit & Integration Testing](#26-phase-13--unit--integration-testing)
27. [Phase 14 — Future / Advanced Features (Not Current Scope)](#27-phase-14--future--advanced-features-not-current-scope)
28. [Core Data Models](#28-core-data-models)
29. [Global Application States](#29-global-application-states)
30. [API Endpoints Reference](#30-api-endpoints-reference)
31. [Environment Setup Reference](#31-environment-setup-reference)
32. [Implemented Features Log (Updated Per Stage)](#32-implemented-features-log-updated-per-stage)

---

## 1. PROJECT OVERVIEW

### What is FLIGHTLY?

**FLIGHTLY** is a mobile flight booking application built as a graduation project. It allows users
to search for flights, compare prices, manage bookings, save favorite routes, and manage their
travel profile — all from a modern, polished mobile app experience.

### Who is the Developer?

A fresh/beginner developer with zero previous mobile development experience. All instructions in
this file must be explained clearly, step by step, as if teaching for the very first time.

### Target Platform

- **Primary:** Mobile (iOS and Android) using Flutter (Dart)
- **Supporting Backend:** Simple microservices-based REST API

### Academic Purpose

This project is a graduation project and must:
- Demonstrate a working, full-stack mobile application
- Apply Microservices Architecture (explained and implemented, not just referenced)
- Be fully defensible in a graduation discussion/presentation
- Include unit and integration tests (basic, beginner-level)
- Be documented throughout with clean code and descriptive comments

### Project Scope Summary (MVP — Minimum Viable Product)

The MVP includes:
- Onboarding screens (first-launch only)
- Authentication (Sign Up, Login, Forgot Password)
- Flight Search (one-way and round-trip)
- Flight Results with filtering and sorting
- Flight Details page
- Booking flow (traveler info, overview, dummy payment, confirmation)
- Saved Flights / Watchlist
- My Trips (upcoming and past)
- Account & Profile management
- Notifications (in-app and push)
- System states (loading, error, empty, retry, offline)

NOT in MVP scope (future enhancements):
- AI Travel Assistant / Smart Chatbot
- Real payment gateway integration
- Ticket modification or cancellation
- Full multilingual translation
- Loyalty program integration
- Multi-city planner

---

## 2. TECHNOLOGY STACK DECISIONS

### Why These Technologies? (Explained for Beginners)

#### Frontend: Flutter (Dart) — Latest Stable Version

**What is it?**
Flutter is Google's UI toolkit for building beautiful apps from a single codebase that runs on
both iOS and Android. Dart is the programming language used with Flutter.

**Why Flutter?**
- One codebase runs on both iOS and Android (saves time)
- Very fast performance, near-native speed
- Beautiful animations built in
- Large community and documentation
- Perfect for beginners because of its widget-based approach

**Current Version to Use:** Always check https://flutter.dev for the latest stable version.
At time of writing: Flutter 3.x (latest stable).

#### Backend: Node.js with Express.js (Microservices)

**What is Node.js?**
Node.js lets you run JavaScript on the server (not just in a browser). It's fast, lightweight,
and beginner-friendly.

**What is Express.js?**
Express is a simple web framework for Node.js. It makes creating APIs (the "bridge" between
your mobile app and the database) very easy.

**Why Node.js + Express?**
- Simple to learn and understand
- Very fast to set up
- Huge community and many tutorials
- Works perfectly with microservices pattern
- Easy to run and test locally

#### Database: PostgreSQL (Primary) + Redis (Caching/Sessions)

**What is PostgreSQL?**
A reliable, open-source relational database. Think of it like an advanced spreadsheet that
stores your data in tables with rows and columns.

**Why PostgreSQL?**
- Free and open source
- Very reliable and used in real production apps
- Excellent for storing structured data (users, bookings, flights)
- Works perfectly with Node.js

**What is Redis?**
Redis is an in-memory data store — think of it as a super-fast temporary storage. It's used for:
- Storing user sessions (who is logged in)
- Caching search results (so the same search doesn't hit the database every time)

**Why Redis?**
- Very fast (stores data in RAM)
- Perfect for session management
- Simple to understand and use

#### API Communication: REST API (HTTP/JSON)

**What is a REST API?**
A REST API is a set of rules for how your mobile app talks to your backend. The app sends a
request (like "give me flights from Cairo to Dubai") and the backend sends back a response
(like a list of flights in JSON format).

**JSON** is just a text format for sending data — looks like: `{ "city": "Cairo", "code": "CAI" }`

#### API Documentation: Swagger (OpenAPI)

**What is Swagger?**
Swagger automatically creates interactive documentation for your API. You can see all your
endpoints and test them in a browser — very useful for testing without writing code.

#### Authentication: JWT (JSON Web Tokens)

**What is JWT?**
When a user logs in, the server gives them a "token" (like a ticket). The user's app sends this
token with every request so the server knows who they are. Tokens expire after a set time.

**Why JWT?**
- Industry standard
- Stateless (server doesn't need to remember sessions in most cases)
- Easy to understand and implement

#### Icon Library: Lucide Icons (lucide.dev)

**Why Lucide?**
- 100% free and open source (MIT license)
- Clean, modern, consistent icon set
- Available as Flutter package: `lucide_icons`
- Used consistently throughout the entire project

**This is the ONLY icon source for the entire project.**

#### Charts: fl_chart (Flutter-native chart library)

**Why fl_chart?**
- Flutter-native (not a web library wrapped)
- Better performance than charts.js on mobile
- Free and open source
- Beautiful, animated charts

#### Alerts / Popups: awesome_dialog + flutter_animated_dialog

**Why not SweetAlert2?**
SweetAlert2 is a JavaScript library for web, not Flutter. The Flutter equivalent that matches
its look and capability is `awesome_dialog` package.

#### Toast Notifications: fluttertoast + top_snackbar_flutter

**Why these?**
- `fluttertoast` is the most used toast library in Flutter
- `top_snackbar_flutter` gives beautiful top-positioned toasts
- Both are free and production-ready

#### Celebrations / Confetti: confetti (Flutter package)

**Why confetti?**
- Flutter-native confetti animation
- Replaces canvas-confetti (which is JavaScript, not Flutter)
- Free and easy to implement

#### Onboarding Tours: introduction_screen (Flutter package)

**Why introduction_screen?**
- Flutter-native onboarding flow
- Replaces Customer.js (which is JavaScript)
- Supports swipe, dots indicator, skip logic
- Free and widely used

#### Loading States: shimmer + flutter_spinkit

**Why these?**
- `shimmer` creates skeleton loading screens (like Facebook's gray loading effect)
- `flutter_spinkit` provides various beautiful loading spinners
- Both are free Flutter packages

#### State Management: Riverpod (flutter_riverpod)

**What is state management?**
When your app's data changes (like a user logs in), every part of the UI that needs to update
must know about that change. State management is the system that handles this.

**Why Riverpod?**
- Modern, recommended for Flutter
- Easy for beginners once explained
- Type-safe and prevents common bugs
- Good separation of UI and business logic

#### HTTP Requests: Dio

**What is Dio?**
Dio is a Flutter package for making HTTP requests (calling your API). It's more powerful than
Flutter's built-in http package and easier to configure.

#### Local Storage: flutter_secure_storage + shared_preferences

**Why two storages?**
- `flutter_secure_storage`: For sensitive data (tokens, passwords) — encrypted
- `shared_preferences`: For simple settings (onboarding completed, language preference)

#### Image Handling: cached_network_image + image_picker

**Why these?**
- `cached_network_image`: Downloads images from URLs and caches them locally so they load fast
  next time (with placeholder and error states built in)
- `image_picker`: Lets user pick photos from gallery or camera (for profile photo)

#### Load Balancing: NGINX (as reverse proxy)

**What is NGINX?**
NGINX is a web server that sits in front of your microservices and distributes incoming requests.
If many users use the app at once, NGINX routes them to available service instances.

**Why NGINX?**
- Free and open source
- Industry standard for load balancing
- Simple configuration for beginners
- Handles many users simultaneously

#### Containerization: Docker + Docker Compose

**What is Docker?**
Docker puts each service (like "auth service" or "flight service") in its own isolated box called
a container. This means each service runs independently and won't affect the others.

**What is Docker Compose?**
Docker Compose lets you start all your services (database, redis, all microservices, nginx) with
a single command: `docker-compose up`.

**Why Docker?**
- Each microservice runs in isolation
- Easy to start, stop, and manage all services
- Works the same on any computer
- Industry standard for microservices deployment

---

## 3. ARCHITECTURE: MICROSERVICES EXPLAINED

### What is Microservices Architecture?

Imagine a traditional restaurant where one person cooks, takes orders, cleans tables, and manages
billing. If that one person gets sick — everything stops. That's called a **Monolithic** approach.

Now imagine a restaurant where:
- One person only takes orders (API Gateway)
- A cook only handles cooking (Flight Service)
- A cashier only handles money (Payment Service)
- A host only manages guests (Auth Service)

If the cashier gets sick, food still gets cooked. People still get seated. This is **Microservices**.

### Why Microservices for FLIGHTLY?

| Benefit | How it Applies to FLIGHTLY |
|---------|---------------------------|
| Independent scaling | If many users search flights, only scale the Flight Search service |
| Fault isolation | If Payment service fails, users can still search and browse flights |
| Easy to extend | Add AI Travel Assistant later as a new service without touching existing code |
| Clear separation | Each developer (or feature phase) touches only one service |
| Academic value | Demonstrates knowledge of modern architecture patterns |

### FLIGHTLY Microservices Architecture Map

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER MOBILE APP                        │
│                    (iOS + Android Client)                         │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS Requests
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    NGINX (Load Balancer)                          │
│              Routes requests, handles SSL termination            │
└──────┬────────┬──────────┬──────────┬───────────┬──────────────┘
       │        │          │          │           │
       ▼        ▼          ▼          ▼           ▼
┌──────────┐ ┌──────────┐ ┌────────┐ ┌─────────┐ ┌────────────┐
│  AUTH    │ │ FLIGHT   │ │BOOKING │ │NOTIF.   │ │  USER      │
│ SERVICE  │ │ SERVICE  │ │SERVICE │ │SERVICE  │ │  SERVICE   │
│          │ │          │ │        │ │         │ │            │
│• Sign Up │ │• Search  │ │• Book  │ │• Push   │ │• Profile   │
│• Login   │ │• Results │ │• Pay   │ │• In-app │ │• Passengers│
│• JWT     │ │• Details │ │• Trips │ │• Alerts │ │• Settings  │
│• Password│ │• Filter  │ │• Ref#  │ │• Prefs  │ │• Saved     │
└────┬─────┘ └────┬─────┘ └───┬────┘ └────┬────┘ └─────┬──────┘
     │            │           │           │             │
     └────────────┴───────────┴───────────┴─────────────┘
                              │
               ┌──────────────┴───────────────┐
               ▼                              ▼
    ┌─────────────────────┐       ┌───────────────────────┐
    │   PostgreSQL DB      │       │     Redis Cache        │
    │  (Persistent Data)   │       │  (Sessions/Caching)    │
    │                      │       │                        │
    │  • users table       │       │  • Auth tokens         │
    │  • flights table     │       │  • Search result cache │
    │  • bookings table    │       │  • Session data        │
    │  • passengers table  │       │                        │
    │  • saved_flights tbl │       │                        │
    │  • notifications tbl │       │                        │
    └─────────────────────┘       └───────────────────────┘
```

### Microservices Breakdown

| Service | Port | Responsibility |
|---------|------|----------------|
| API Gateway (NGINX) | 80/443 | Routes, load balancing, SSL |
| Auth Service | 3001 | Registration, login, JWT, password reset |
| Flight Service | 3002 | Search, results, filtering, flight details |
| Booking Service | 3003 | Reservations, booking management, trips |
| User Service | 3004 | Profile, passengers, saved flights, settings |
| Notification Service | 3005 | Push notifications, in-app alerts, preferences |

---

## 4. MANDATORY DEVELOPMENT RULES (GOLDEN RULES)

These rules are absolute. They must NEVER be violated.

### Rule 1: Code-First, Not Database-First, Not Frontend-First

**What this means:**
- Do NOT design the database tables first and then write code around them
- Do NOT build the mobile UI first without a working backend
- ALWAYS write code that defines behavior, and let the database and UI follow

**Correct order for every feature:**
1. Write the backend service code (business logic)
2. Run database migrations (let the code define what tables are needed)
3. Build and connect the mobile UI
4. Test end-to-end

### Rule 2: One Complete Feature Per Stage

- Each stage implements exactly ONE complete feature
- A "complete feature" means: backend + database + mobile UI + testing all working together
- Do NOT move to the next stage until the current stage is confirmed working

### Rule 3: Never Skip Error Handling

- Every API endpoint must handle errors and return meaningful error messages
- Every Flutter screen must handle loading, error, and empty states
- Never leave a `try/catch` block empty

### Rule 4: No Hardcoded Sensitive Data

- API keys, database passwords, JWT secrets must NEVER be hardcoded in source code
- ALWAYS use `.env` files for environment variables
- `.env` files must be in `.gitignore` — NEVER pushed to GitHub

### Rule 5: Clean Code Always

- Use descriptive variable names (not `x`, `d`, `temp`)
- Write comments explaining WHY, not just WHAT
- One function = one responsibility
- Remove unused code and debug logs before committing

### Rule 6: Mandatory Development Pattern (Repeated for Every Feature)

```
For every single feature:
Step 1 → Write backend service code
Step 2 → Create database migration (tables/columns)
Step 3 → Test backend with Postman or Swagger
Step 4 → Verify database records directly
Step 5 → Build Flutter mobile UI
Step 6 → Connect UI to backend API
Step 7 → Manual end-to-end testing
Step 8 → Demo: show what appears on screen
Step 9 → Commit code to GitHub with descriptive message
Step 10 → Update README.md
Step 11 → Wait for student confirmation
Step 12 → Move to next feature ONLY after confirmation
```

---

## 5. STAGE-BY-STAGE DEVELOPMENT PROTOCOL

### How Stages Work

- Each stage = one complete, testable feature
- Stages are sequential — do not skip or combine
- Every stage ends with: **"Please test the above checklist and confirm with: 'Stage done and run correctly with no errors'"**
- Do NOT continue to the next stage automatically
- If a stage is long, stop at a logical checkpoint and wait

### Stage Response Format

Each stage response must include:

```
STAGE [NUMBER]: [STAGE NAME]
─────────────────────────────
WHAT WE ARE BUILDING:
[Clear explanation of what this stage does]

WHY THIS STAGE NOW:
[Why this comes before other features]

EXPLANATION FOR BEGINNERS:
[Teach the student what concepts are used]

FILES TO CREATE/MODIFY:
[Complete list of all files with full paths]

CODE:
[Full, complete code — no truncation, no "add the rest here"]

MANUAL TESTING CHECKLIST:
□ [Test item 1] — How: [how to test] — Expected: [what you should see]
□ [Test item 2] — How: [how to test] — Expected: [what you should see]
...

DEMO OUTPUT:
[What the student should see on screen / in Postman / in database]

COMMIT MESSAGE:
git commit -m "feat: [describe what was implemented]"

─────────────────────────────
Please test the above checklist and confirm with:
"Stage done and run correctly with no errors"
─────────────────────────────
```

---

## 6. TESTING RULES

### General Testing Philosophy

You are a beginner with zero testing experience. Testing will be explained as you go.
There are two main types of tests:

**Unit Tests:** Test ONE small piece of code in isolation.
Example: "Test that the email validation function correctly rejects 'not-an-email'"

**Integration Tests:** Test how multiple pieces work TOGETHER.
Example: "Test that when a user signs up with valid data, the database gets a new user record AND the API returns a success response"

### When Testing Happens

- A small amount of testing is added during development (for critical functions)
- A dedicated **Phase 13 (Testing Phase)** happens at the end of the project
- The Testing Phase will be explained fully when we reach it

### Manual Testing Checklist (Required at End of Every Stage)

Every stage must include this checklist format:

```
MANUAL TESTING CHECKLIST — Stage [N]: [Name]
─────────────────────────────────────────────

API TESTING (if backend exists in this stage):
□ Endpoint [METHOD /path] — Test with Postman — Expected: [response]
□ Endpoint [METHOD /path] — Test invalid input — Expected: [error response]

DATABASE VERIFICATION (if database changes exist):
□ Check table [table_name] exists — How: connect to PostgreSQL and run: SELECT * FROM [table]
□ Verify record created — How: check row appears after action
□ Verify data integrity — How: check data matches what was submitted

MOBILE UI VERIFICATION:
□ Screen [name] loads correctly — Expected: [what you see]
□ Action [button/interaction] works — Expected: [what happens]
□ Error state displays — Expected: [error message shown]
□ Loading state shows — Expected: [spinner/skeleton visible]
□ Empty state shows — Expected: [empty illustration shown]

ERROR HANDLING:
□ Submit invalid data — Expected: appropriate error message shown
□ Disconnect internet — Expected: offline/error state shown
□ Retry after error — Expected: data loads successfully
─────────────────────────────────────────────
```

---

## 7. DOCUMENTATION RULES

### README.md Structure

The README.md must always contain:

```markdown
# FLIGHTLY — Flight Booking App

## Project Overview
## Architecture
## Technology Stack
## Prerequisites & Installation
## Running the Project
## Environment Variables
## Implemented Features (updated after each stage)
## API Endpoints (updated after each stage)
## Testing
## Known Issues
## Future Enhancements
## Commit History
```

### Code Comment Rules

```dart
// ✅ GOOD COMMENT — explains WHY
// We validate passport number before saving because some airlines
// reject bookings with invalid passport formats at check-in.
String? validatePassport(String passport) { ... }

// ❌ BAD COMMENT — just repeats the code
// This validates the passport
String? validatePassport(String passport) { ... }
```

### Comment Standards by File Type

```javascript
// Node.js/Express Service files:
// Each function must have a JSDoc comment explaining purpose, params, returns

/**
 * Authenticates a user by email and password.
 * Returns a JWT token on success, throws AuthError on failure.
 * @param {string} email - User's email address
 * @param {string} password - User's plain-text password
 * @returns {Promise<{token: string, user: UserObject}>}
 */
async function loginUser(email, password) { ... }
```

```dart
// Flutter/Dart files:
/// Each widget/function must have a doc comment explaining purpose

/// Displays a flight search card with origin, destination, and date.
/// Tapping the card navigates to the flight details screen.
/// [flight] - The FlightModel object containing all flight data.
class FlightCard extends StatelessWidget { ... }
```

---

## 8. GIT & GITHUB RULES

### Setup Instructions (For a Complete Beginner)

**Step 1: Install Git on your computer**
```bash
# Check if Git is installed:
git --version
# If not installed, download from: https://git-scm.com/downloads
```

**Step 2: Configure Git with your name and email**
```bash
git config --global user.name "Your Full Name"
git config --global user.email "youremail@example.com"
```

**Step 3: Create a GitHub account**
- Go to https://github.com
- Click "Sign Up"
- Create a free account

**Step 4: Create a new private repository on GitHub**
- Click the "+" button at the top right on GitHub
- Click "New repository"
- Name it: `flightly-app`
- Select "Private"
- Do NOT initialize with README (we'll push our own)
- Click "Create repository"

**Step 5: Connect your local project to GitHub**
```bash
# Inside your project folder:
git init
git remote add origin https://github.com/YOUR_USERNAME/flightly-app.git
```

**Step 6: Create .gitignore BEFORE first commit**
```
# .gitignore file contents
.env
.env.local
.env.*.local
node_modules/
.flutter-plugins
.flutter-plugins-dependencies
build/
*.g.dart
*.freezed.dart
.dart_tool/
.idea/
*.iml
*.log
```

### Commit Rules

- One commit per completed stage
- Commit message format: `feat: [brief description of what was implemented]`
- Examples:
  - `feat: implement user authentication with JWT`
  - `feat: add flight search screen with airport autocomplete`
  - `feat: implement booking flow with passenger management`

### Commit Workflow (After Every Stage)

```bash
git add .
git commit -m "feat: [describe completed feature]"
git push origin main
```

### Branching Strategy (Simple for Beginners)

For this project, we use a simple single-branch approach:
- `main` branch — the only branch
- All work goes directly to `main`
- This is appropriate for a solo graduation project

---

## 9. UI/UX & DESIGN RULES

### Design Philosophy

- **Modern and stylish** — looks like a production app, not a tutorial project
- **Animated but not slow** — transitions and micro-animations that don't affect performance
- **Comfortable for eyes** — avoid harsh colors, ensure good contrast
- **Wow factor** — first impression must impress

### Color Palette

Use a consistent color system defined as constants:
```dart
// lib/core/theme/app_colors.dart
class AppColors {
  static const Color primary = Color(0xFF1A73E8);      // Main blue
  static const Color primaryDark = Color(0xFF1557B0);  // Dark blue
  static const Color accent = Color(0xFF34A853);       // Green (success)
  static const Color error = Color(0xFFEA4335);        // Red (errors)
  static const Color warning = Color(0xFFFBBC04);      // Yellow (warnings)
  static const Color surface = Color(0xFFFFFFFF);      // White cards
  static const Color background = Color(0xFFF8F9FA);   // Light gray bg
  static const Color textPrimary = Color(0xFF202124);  // Near-black text
  static const Color textSecondary = Color(0xFF5F6368); // Gray text
  static const Color divider = Color(0xFFE8EAED);      // Light dividers
}
```

### Typography

```dart
// lib/core/theme/app_text_styles.dart
// Use Google Fonts — 'Inter' as primary font
// Clean, modern, widely supported
```

### Icon System: Lucide Icons ONLY

- Package: `lucide_icons: ^0.x.x` (check latest version)
- Example usage: `LucideIcons.search`, `LucideIcons.plane`, `LucideIcons.user`
- NEVER use emojis as icons
- NEVER mix icon libraries

### Animation Rules

- Page transitions: Use `PageRouteBuilder` with slide or fade transitions (300ms max)
- Button press: Scale down to 0.95 on press, back to 1.0 on release
- Loading: Use shimmer for content loading, spinner for action loading
- Success: Brief scale + opacity animation on success states
- No animation should take more than 400ms (keeps UI feeling fast)

### Navigation: Bottom Navigation Bar

The app has a persistent bottom navigation bar with tabs:
```
[Search/Home] [My Trips] [Watch/Saved] [Account]
   (plane)      (clock)    (bookmark)    (user)
```

Rules:
- Bottom nav visible on all main screens
- Hidden during onboarding and auth screens
- Selected tab highlighted
- Tab switching preserves state (don't reload on tab switch)

### Loading Experience

Apply consistently across the app:
- **Skeleton screens** for content lists (shimmer effect)
- **Spinner overlays** for actions (submit, pay, search)
- **Progress indicators** for multi-step flows (booking steps)
- No UI should block the user unnecessarily during loading
- Timeout after 30 seconds with a retry option

### Password Field Special Effect

- Password field shows animated "blinking eyes" icon that "close" when password is hidden
- Use custom animated icon: open eye (password visible) ↔ closed eye (password hidden)
- This is implemented as a small cute animation, not just an icon swap

### Onboarding Tour (First Visit Only)

- Show walkthrough tooltips/highlights on the first time a user reaches the Home screen
- Use `introduction_screen` or custom tour to highlight: Search, My Trips, Watch tab, Account
- Only shown once per account, never again

### Confetti / Celebrations

- Show confetti animation when: booking confirmed, registration successful
- Use `confetti` Flutter package
- Duration: 3-4 seconds
- Colors: Match app primary palette

### Alerts & Popups

- Use `awesome_dialog` package for all modal dialogs
- Use `top_snackbar_flutter` for toast notifications
- Consistent usage:
  - ✅ Success: Green with checkmark
  - ❌ Error: Red with X
  - ⚠️ Warning: Orange with exclamation
  - ℹ️ Info: Blue with info icon

---

## 10. SECURITY RULES

### API Keys & Sensitive Data

```
GOLDEN RULE: If it's a secret, it goes in .env. NEVER in code.
```

**What goes in .env:**
- Database connection string (host, port, username, password, database name)
- JWT secret key
- Redis connection URL
- Any third-party API keys (if added in future)
- SMTP credentials (if email is added)

**.env file example (NEVER commit this file):**
```env
# Auth Service
JWT_SECRET=your_very_long_random_secret_here
JWT_EXPIRES_IN=7d

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=flightly_db
DB_USER=flightly_user
DB_PASSWORD=your_secure_password_here

# Redis
REDIS_URL=redis://localhost:6379

# App
NODE_ENV=development
PORT=3001
```

**.env.example file (DO commit this — shows what variables are needed without values):**
```env
JWT_SECRET=
JWT_EXPIRES_IN=
DB_HOST=
DB_PORT=
DB_NAME=
DB_USER=
DB_PASSWORD=
REDIS_URL=
NODE_ENV=
PORT=
```

### Authentication Security

- Passwords must be hashed using bcrypt (never store plain passwords)
- JWT tokens expire after 7 days
- Refresh token rotation for extended sessions
- Rate limiting on auth endpoints (max 5 failed login attempts before temporary block)
- Case-insensitive email handling (store emails as lowercase in database)

### Input Validation & Sanitization

- Validate ALL inputs on both client (Flutter) and server (Node.js)
- Never trust data from the mobile app alone
- Sanitize inputs to prevent SQL injection (use parameterized queries, never string concatenation)

---

## 11. ERROR HANDLING & LEARNING MODE

### When an Error Occurs

Every error that appears must be handled with this pattern:

```
1. ERROR MESSAGE: Show the exact error message to the student
2. WHY IT HAPPENED: Explain the root cause in simple terms
3. HOW TO DEBUG: Show step-by-step debugging approach
4. CORRECT FIX: Provide the exact fix with corrected code
5. HOW TO AVOID: Explain how to prevent this error in the future
```

**Example Error Handling:**
```
ERROR: "Cannot read properties of undefined (reading 'id')"

WHY IT HAPPENED:
You're trying to access `.id` on a variable that is `undefined` (has no value yet).
This usually happens when async data hasn't loaded yet, or when an API call failed
but the code continues running as if it succeeded.

HOW TO DEBUG:
1. Add console.log above the failing line to see what the variable contains
2. Check if the API call before it is actually succeeding (check the response)
3. Check if there's a missing await keyword on an async function

CORRECT FIX:
// Before (causes error):
const userId = user.id;

// After (safe):
const userId = user?.id;  // The ?. is called "optional chaining" — 
                           // it returns undefined instead of crashing if user is undefined

HOW TO AVOID:
Always use optional chaining (?.) when accessing properties of objects that might
be null or undefined, especially data coming from API responses.
```

---

## 12. FEATURE CHECKLIST (ALL PHASES)

Use this checklist to track progress. Update it as each feature is completed.

### Phase 0 — Project Setup
- [ ] Flutter project created with correct structure
- [ ] All packages and dependencies installed
- [ ] Node.js + Express project scaffolded
- [ ] PostgreSQL database created and connected
- [ ] Redis installed and connected
- [ ] Docker + Docker Compose configured
- [ ] NGINX configured
- [ ] .env files set up (with .gitignore)
- [ ] Git repository initialized and pushed to GitHub
- [ ] README.md created

### Phase 1 — Onboarding
- [ ] 3 onboarding screens designed and implemented
- [ ] Swipe left/right navigation between screens
- [ ] Next arrow button navigation
- [ ] Skip button (from any screen, routes to Auth)
- [ ] Enable Notifications button with native permission popup
- [ ] Handle: Allow notifications flow
- [ ] Handle: Deny notifications flow
- [ ] Handle: Already granted (skip popup)
- [ ] Onboarding shown only on first launch
- [ ] Flag persisted: onboardingCompleted = true
- [ ] Flag persisted: notificationPermissionStatus
- [ ] Flag persisted: firstLaunchCompleted = true
- [ ] Back button disabled on Auth screen after onboarding
- [ ] Pagination dots update with swipe and arrow
- [ ] Backward swipe supported
- [ ] Edge case: user taps skip immediately
- [ ] Edge case: rapid multiple taps
- [ ] Edge case: partial swipe

### Phase 2 — Authentication
- [ ] Auth Landing screen (Login button, Register button, Google dummy, Facebook dummy, Skip to Guest)
- [ ] Login screen with email + password fields
- [ ] Animated password eye effect (open/close eyes)
- [ ] Login validation: empty fields
- [ ] Login validation: invalid email format
- [ ] Login validation: wrong credentials error message
- [ ] Prevent multiple login taps (debounce)
- [ ] Register screen with email, password, re-enter password
- [ ] Register validation: all fields required
- [ ] Register validation: valid email format
- [ ] Register validation: passwords match
- [ ] Register validation: password minimum rules
- [ ] Prevent duplicate accounts (case-insensitive email)
- [ ] "Email already registered" error message
- [ ] "Successful registration" confirmation
- [ ] Redirect to Login after successful registration
- [ ] Navigation: Auth Landing → Login
- [ ] Navigation: Auth Landing → Register
- [ ] Navigation: Register success → Login
- [ ] Navigation: Login success → App Home
- [ ] Back navigation: Login → Auth Landing
- [ ] Back navigation: Register → Auth Landing
- [ ] Preserve form data when navigating back
- [ ] Google/Facebook buttons: visible but disabled (no backend)
- [ ] Skip button routes to Home as Guest
- [ ] Guest session state tracked
- [ ] JWT token stored securely on login
- [ ] Session persists across app restart
- [ ] Forgot Password flow
- [ ] Edge case: rapid multiple register taps
- [ ] Edge case: network failure
- [ ] Edge case: existing email with different case

### Phase 3 — Flight Search
- [ ] Home Search screen
- [ ] Origin/Destination input fields
- [ ] Airport Search Popup (tap From/To)
- [ ] Search by airport code (CAI)
- [ ] Search by airport name
- [ ] Search by city name
- [ ] Search by country/capital name
- [ ] Dynamic autocomplete results while typing
- [ ] Recent/history airports shown before typing
- [ ] "No results found" empty state
- [ ] Selected airport populates form
- [ ] Swap origin/destination button
- [ ] Validation: origin ≠ destination
- [ ] One-way / Round-trip selector
- [ ] Date selection calendar (departure)
- [ ] Date selection calendar (return, if round-trip)
- [ ] Validation: return date cannot be before departure
- [ ] Past dates disabled
- [ ] Switching Return → One-Way: removes return date
- [ ] Switching One-Way → Return: prompts for return date
- [ ] Passenger popup: Adults, Children, Infants
- [ ] Cabin class selection (Economy, Business, First, Premium Economy)
- [ ] Cabin class: single select only
- [ ] Min 1 adult required
- [ ] Child/infant ratio validation (1 adult per child/infant)
- [ ] Max 8 total passengers
- [ ] Passenger counts cannot go below zero
- [ ] Passenger summary populates home screen
- [ ] Search button validation: all fields required
- [ ] Loading state while searching
- [ ] Navigate to results on valid search
- [ ] Show validation errors on invalid search
- [ ] Prevent rapid multiple search taps
- [ ] Search form state preserved when returning from results
- [ ] Search history saved (recent searches)
- [ ] Edge case: child/infant only booking blocked
- [ ] Edge case: exceeds adult ratio
- [ ] Edge case: exceeds passenger limit
- [ ] Edge case: no internet / API unavailable

### Phase 4 — Flight Results, Filtering & Sorting
- [ ] Results listing screen
- [ ] Flight cards with: airline, price, times, duration, stops, labels
- [ ] "Best / Cheapest / Fastest" labels on cards
- [ ] Expandable flight cards (first tap = expand)
- [ ] Second tap on expanded card → navigate to details
- [ ] Default sorting: best price on first load
- [ ] Scrollable results list
- [ ] Flight result pagination / infinite scroll
- [ ] No-results handling (show no-results screen)
- [ ] Airline logos displayed
- [ ] Layover/stops display
- [ ] Fare breakdown visible on card
- [ ] Filter icon (top right) opens Filter screen
- [ ] Filter: Stops options
- [ ] Filter: Price range slider
- [ ] Filter: Duration slider
- [ ] Filter: Departure time
- [ ] Filter: Arrival time
- [ ] Filter: Return time
- [ ] Filter: Carriers (multi-select)
- [ ] Filter: Class (single-select)
- [ ] Filters combine together
- [ ] Filters NOT applied until Apply button tapped
- [ ] Apply button returns to results with filtered data
- [ ] Clear/Reset restores defaults
- [ ] Filter selections persist when reopening filter screen
- [ ] Class row on filter shows selected class after selection
- [ ] Carriers row shows selected airlines after selection
- [ ] Sort by price
- [ ] Sort by duration
- [ ] Sort by departure/arrival time
- [ ] Scroll position preserved after filter/sort
- [ ] Scroll position preserved when going back from details
- [ ] Edge case: filters produce no results
- [ ] Edge case: contradictory filters
- [ ] Edge case: leaving filter without applying (discard)
- [ ] Edge case: clearing filters restores original results

### Phase 5 — Flight Details & Smart Pricing
- [ ] Full itinerary details screen
- [ ] Outbound flight segments
- [ ] Return flight segments (if round-trip)
- [ ] Layover details (duration, airport)
- [ ] Airline information
- [ ] Pricing summary
- [ ] Fare rules and conditions
- [ ] Baggage details (cabin + checked)
- [ ] Refund/change policy
- [ ] Fare class details (Economy/Business/etc.)
- [ ] Seat availability display
- [ ] "Book Now" button
- [ ] Save/Favorite flight button
- [ ] Dynamic pricing logic (show price variations)
- [ ] Best flight recommendation label
- [ ] Cheapest option label
- [ ] Fastest option label
- [ ] Value-for-money recommendation
- [ ] Price change indicators (up/down arrows)
- [ ] Edge case: price changed after selecting flight
- [ ] Edge case: flight becomes unavailable
- [ ] Edge case: empty/partial segment data
- [ ] Edge case: Book Now after price changed → prompt to accept updated fare

### Phase 6 — Booking & Reservation
- [ ] Booking screen with selected flight summary
- [ ] Passenger list screen
- [ ] Select existing passenger from saved list
- [ ] Add New Passenger form
- [ ] Edit existing passenger
- [ ] Delete passenger (with confirmation prompt)
- [ ] Passenger fields: full name, gender, DOB, nationality, passport number
- [ ] Date of Birth wheel/scroll picker popup
- [ ] Nationality selector (scrollable list)
- [ ] Passenger validation: all required fields
- [ ] Passport format validation
- [ ] DOB cannot be future date
- [ ] Passenger age compliance (adult/child/infant rules)
- [ ] Contact details form (email + phone)
- [ ] Contact details validation
- [ ] Multiple passengers selectable (if booking count > 1)
- [ ] Booking price updates based on passenger count
- [ ] Booking summary overview screen
- [ ] Itinerary review on overview
- [ ] Passenger details review on overview
- [ ] Pricing breakdown on overview
- [ ] Proceed to Payment button
- [ ] Back navigation allows editing booking before payment
- [ ] Booking reference ID generated
- [ ] Booking saved to database
- [ ] Edge case: passenger added but not selected
- [ ] Edge case: duplicate passport number blocked
- [ ] Edge case: required booking info missing
- [ ] Edge case: user leaves booking mid-flow (resume or discard prompt)
- [ ] Edge case: price changes between overview and payment

### Phase 7 — Payment (Dummy Scope)
- [ ] Payment screen with card fields (UI only)
- [ ] Card number field (mock validation only)
- [ ] Expiry date field
- [ ] CVV field
- [ ] Cardholder name field
- [ ] Pay Now button
- [ ] Prevent multiple Pay Now taps (duplicate protection)
- [ ] Simulated payment processing state (loading)
- [ ] Simulated payment success
- [ ] Navigate to Confirmation screen
- [ ] Confirmation screen: success state
- [ ] Confirmation: ticket confirmation number
- [ ] Confirmation: booking reference
- [ ] Confirmation: full itinerary
- [ ] Confirmation: passenger details
- [ ] Confirmation: paid amount
- [ ] Confetti animation on booking confirmation
- [ ] "Go Home" button
- [ ] Booking data saved persistently (available in My Trips)
- [ ] Dummy error state (simulated payment failure)
- [ ] Payment failure retry option

### Phase 8 — Notifications & Alerts
- [ ] Push notifications setup (Firebase Cloud Messaging)
- [ ] Notification permission handled (reuse from onboarding)
- [ ] In-app notification list screen
- [ ] Booking confirmation notifications
- [ ] Schedule update notifications (simulated)
- [ ] Price alert notifications (simulated)
- [ ] Fare change alert notifications (simulated)
- [ ] Unread notification badge
- [ ] Mark notification as read
- [ ] Mark all as read
- [ ] Empty state for no notifications
- [ ] Notification preferences in settings

### Phase 9 — Saved Flights / Watch Flow
- [ ] Watch tab accessible from bottom navigation
- [ ] Saved flights list screen
- [ ] Empty state for no saved flights
- [ ] Save flight from Flight Details screen
- [ ] Duplicate detection: "Flight already in watchlist" message
- [ ] Saved flight card: destination, dates, airline, fare snapshot
- [ ] Tap saved flight card → re-run search with saved criteria
- [ ] Three-dot menu on saved flight card
- [ ] View details option in three-dot menu
- [ ] Remove from watchlist option
- [ ] Remove from watchlist updates list immediately
- [ ] Saved flights persist across sessions
- [ ] Watchlist tied to authenticated user
- [ ] Edge case: saved flight no longer available
- [ ] Edge case: saved flight price changed since saved
- [ ] Scroll position preserved in watch list

### Phase 10 — My Trips
- [ ] My Trips screen accessible from bottom navigation
- [ ] Two tabs: Upcoming / History
- [ ] Upcoming trips list
- [ ] Trip card: route, airline, times, date, ticket summary
- [ ] Tap trip card → opens trip details / booking confirmation
- [ ] History trips list
- [ ] Empty state: No upcoming trips
- [ ] Empty state: No trip history
- [ ] Completed bookings auto-populate Upcoming Trips
- [ ] Trip moves from Upcoming → History after travel date passes
- [ ] Booking data persists after app restart / re-login
- [ ] No duplicate bookings in list
- [ ] Preserve selected tab (Upcoming/History)

### Phase 11 — Account & Profile
- [ ] Account hub screen (central menu)
- [ ] Profile menu item → Profile screen
- [ ] My Bookings menu item → My Trips flow
- [ ] Passengers menu item → Passenger management
- [ ] My Cards menu item → dummy cards screen
- [ ] Saved Flights menu item → Watch flow
- [ ] Settings menu item → Settings screen
- [ ] Profile: view/edit name
- [ ] Profile: add/change profile photo (image picker)
- [ ] Profile: edit nationality
- [ ] Profile: edit email
- [ ] Profile: edit phone number
- [ ] Profile: linked accounts (dummy display)
- [ ] Profile: delete account (dummy placeholder)
- [ ] Profile: sign out button (styled red)
- [ ] Sign out confirmation prompt
- [ ] Profile changes persist across sessions
- [ ] Profile edit form validation (email, phone formats)
- [ ] Change Password flow: current password, new password, confirm
- [ ] Change Password validation
- [ ] Passengers: add new passenger
- [ ] Passengers: edit passenger
- [ ] Passengers: delete passenger (with confirmation)
- [ ] My Cards: dummy UI only (no payment gateway)
- [ ] Settings: language preference (UI only, no translation)
- [ ] Settings: country/region selection
- [ ] Settings: notification preference toggles
- [ ] Settings preferences persist after app restart
- [ ] Edge case: invalid profile edits
- [ ] Edge case: password reset failure
- [ ] Edge case: user signs out with unsaved edits (save/discard prompt)
- [ ] All menu items fully navigable

### Phase 12 — System States & Feedback
- [ ] Loading state: shimmer skeleton for lists
- [ ] Loading state: spinner for actions
- [ ] Empty state: all empty screens have illustration + message
- [ ] Error state: all error screens have message + retry button
- [ ] Retry handling: works correctly after retry
- [ ] Offline state: detected and shown gracefully
- [ ] Partial failure state: show what loaded, indicate what failed
- [ ] Success feedback: toast/snackbar on successful actions
- [ ] No flights found state with suggestions
- [ ] Global loading indicator during API calls
- [ ] Timeout after 30 seconds with retry option
- [ ] No UI blocking unnecessarily
- [ ] Smooth animations, no flickering
- [ ] Consistent loading states across all pages

### Phase 13 — Testing (End of Project)
- [ ] Unit tests: auth service (login/register validation)
- [ ] Unit tests: flight search validation
- [ ] Unit tests: booking reference generation
- [ ] Unit tests: passenger validation
- [ ] Integration test: full sign-up → login flow
- [ ] Integration test: search → results → details flow
- [ ] Integration test: booking → confirmation flow
- [ ] All tests passing

---

## 13. PHASE 0 — PROJECT SETUP & ENVIRONMENT

### What We Build in This Phase

This phase sets up the ENTIRE project infrastructure before writing a single feature.
Think of it as building the foundation of a house — you don't put walls up without
a solid foundation.

### What Gets Created

```
flightly/
├── mobile/                      # Flutter mobile app
│   ├── lib/
│   │   ├── core/                # Shared utilities, theme, constants
│   │   ├── features/            # Each feature in its own folder
│   │   └── main.dart            # App entry point
│   ├── pubspec.yaml             # Flutter dependencies
│   └── ...
│
├── services/                    # All backend microservices
│   ├── auth-service/            # Authentication microservice
│   ├── flight-service/          # Flight search microservice
│   ├── booking-service/         # Booking microservice
│   ├── user-service/            # User/profile microservice
│   └── notification-service/    # Notification microservice
│
├── database/
│   └── migrations/              # Database schema files
│
├── nginx/
│   └── nginx.conf               # Load balancer config
│
├── docker-compose.yml           # Start all services with one command
├── .env.example                 # Template for environment variables
├── .gitignore                   # Files to exclude from Git
└── README.md                    # Project documentation
```

### Flutter App Structure (Feature-based Architecture)

```
mobile/lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart   # API URLs, timing constants
│   │   └── route_constants.dart # Named routes
│   ├── errors/
│   │   └── failures.dart        # Custom error types
│   ├── network/
│   │   └── dio_client.dart      # Configured HTTP client
│   ├── theme/
│   │   ├── app_colors.dart      # Color constants
│   │   ├── app_text_styles.dart # Typography
│   │   └── app_theme.dart       # Full theme config
│   ├── utils/
│   │   ├── validators.dart      # Input validation helpers
│   │   └── helpers.dart         # General utility functions
│   └── widgets/
│       ├── loading_widget.dart  # Shimmer/spinner components
│       ├── error_widget.dart    # Error state components
│       └── empty_widget.dart    # Empty state components
│
└── features/
    ├── onboarding/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── auth/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── search/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── results/
    ├── flight_details/
    ├── booking/
    ├── payment/
    ├── my_trips/
    ├── saved_flights/
    ├── account/
    └── notifications/
```

### Backend Service Structure (Each Service is Identical Pattern)

```
services/auth-service/
├── src/
│   ├── controllers/    # Handle HTTP requests, call services
│   ├── services/       # Business logic
│   ├── models/         # Database models/schemas
│   ├── middleware/      # Auth checks, validation, error handling
│   ├── routes/         # API endpoint definitions
│   └── utils/          # Helper functions
├── tests/              # Test files
├── .env                # Environment variables (not in Git)
├── .env.example        # Template (in Git)
├── package.json        # Node.js dependencies
├── Dockerfile          # Container configuration
└── server.js           # Service entry point
```

### Flutter Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.x.x
  riverpod_annotation: ^2.x.x

  # HTTP Client
  dio: ^5.x.x

  # Secure Storage
  flutter_secure_storage: ^9.x.x
  shared_preferences: ^2.x.x

  # Navigation
  go_router: ^13.x.x

  # Icons
  lucide_icons: ^0.x.x

  # UI Components
  awesome_dialog: ^3.x.x
  top_snackbar_flutter: ^3.x.x
  shimmer: ^3.x.x
  flutter_spinkit: ^5.x.x
  confetti: ^0.x.x

  # Images
  cached_network_image: ^3.x.x
  image_picker: ^1.x.x

  # Onboarding
  introduction_screen: ^3.x.x

  # Fonts
  google_fonts: ^6.x.x

  # Charts
  fl_chart: ^0.x.x

  # Date/Time
  intl: ^0.x.x
  table_calendar: ^3.x.x

  # Notifications
  firebase_messaging: ^14.x.x
  flutter_local_notifications: ^16.x.x
  firebase_core: ^2.x.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.x.x
  riverpod_generator: ^2.x.x
  build_runner: ^2.x.x
```

---

## 14. PHASE 1 — ONBOARDING FLOW

### Purpose

Introduce the FLIGHTLY value proposition to new users. Shown ONLY on first app launch
per account. Never shown again after completion or skip.

### Screens

1. **Onboarding Screen 1** — "Find Your Perfect Flight" — hero illustration of travel
2. **Onboarding Screen 2** — "Compare & Save" — show price comparison illustration
3. **Onboarding Screen 3** — "Stay Updated" — notification illustration + Enable Notifications button

### User Actions

| Action | Result |
|--------|--------|
| Swipe left | Go to next onboarding page |
| Swipe right | Go to previous onboarding page |
| Tap next arrow | Go to next page |
| Tap next arrow on last page | Navigate to Auth Landing |
| Tap Skip (any screen) | Navigate to Auth Landing |
| Swipe on last page | Navigate to Auth Landing |
| Tap Enable Notifications | Trigger native permission popup |

### Notification Permission Logic

```
User taps "Enable Notifications":
│
├── IF permission NOT yet requested:
│   └── Show native iOS/Android permission popup
│       ├── User taps "Allow" → permission granted → continue onboarding
│       └── User taps "Don't Allow" → continue onboarding (not blocked)
│
├── IF permission already GRANTED:
│   └── Skip popup, continue onboarding flow
│
└── IF permission already DENIED:
    └── Continue onboarding flow
        (can re-enable from device settings later)
```

### State & Persistence Flags

```dart
// These are stored in SharedPreferences (local device storage)

bool onboardingCompleted = true;
// Meaning: User finished or skipped onboarding.
// App checks this flag on startup — if true, skip onboarding.

String notificationPermissionStatus = "allowed" | "denied" | "not_asked";
// Meaning: Tracks the user's notification permission choice.
// Used in settings and notification features.

bool firstLaunchCompleted = true;
// Meaning: App is no longer in first-time-use mode.
```

### Back Navigation Rule

```
IMPORTANT: When user reaches Auth Landing after onboarding,
pressing back DOES NOTHING (back button is disabled/intercepted).
The user cannot go back to onboarding from Auth.
```

### Pagination Dots Behavior

- Dots update live with both swipe and arrow navigation
- Active dot is larger/filled; inactive dots are smaller/outline
- User CAN swipe backward (previous pages)

### Edge Cases

| Edge Case | Behavior |
|-----------|----------|
| User taps Skip immediately on screen 1 | Navigate to Auth; mark onboarding completed |
| User swipes partially (incomplete swipe) | Snap back to current page |
| Permission denied | Continue flow; no error shown |
| Permission granted | Continue flow; no repeated popup |
| Rapid multiple arrow taps | Debounce; navigate one page at a time |
| App killed during onboarding | Resume from screen 1 next launch (onboarding not completed yet) |

### Data Flow

```
onboardingCompleted → stored in SharedPreferences → checked at app startup
notificationPermissionStatus → stored in SharedPreferences → used in settings
firstLaunchCompleted → stored in SharedPreferences → used for onboarding tour
```

---

## 15. PHASE 2 — AUTHENTICATION FLOW

### Purpose

Entry point for all users after onboarding. Handles login, registration, guest access,
and forgotten passwords. Routes authenticated users to the main app.

### Screens

1. Auth Landing Screen
2. Login Screen
3. Register Screen
4. Forgot Password Screen

### Auth Landing Screen

Buttons present:
- **Login** → navigate to Login screen
- **Register New Account** → navigate to Register screen
- **Google** → dummy button (disabled, no backend integration)
- **Facebook** → dummy button (disabled, no backend integration)
- **Skip** (top right) → route to Home as **Guest** (guestModeSession = true)

### Login Screen — Full Logic

**Fields:**
- Email (text input, keyboard type: email)
- Password (text input, obscured, with animated eye icon effect)

**On Login Button Tap:**
```
Validate locally:
├── Empty email → show "Please enter your email"
├── Invalid email format → show "Please enter a valid email"
├── Empty password → show "Please enter your password"
└── All valid → send to API

API Response:
├── 200 OK → store JWT token securely → navigate to App Home
├── 401 Unauthorized → show "Wrong email or password"
├── 429 Too Many Requests → show "Too many attempts, try again later"
└── Network error → show "Connection error. Please check your internet"
```

**Validation Rules:**
- Empty fields: show inline error below field
- Invalid email format: show inline error
- Incorrect credentials: show toast/snackbar error
- Prevent login request if client-side validation fails (don't hit server)

**Debounce:** Login button disabled for 2 seconds after first tap to prevent duplicates

**Animated Password Eye:**
- When password is hidden: show "closed eye" animation (eyelids close with a blink)
- When password is visible: show "open eye" animation (eyelids open)
- This is an animated toggle, not just a static icon swap

### Register Screen — Full Logic

**Fields:**
- Email (text input, keyboard type: email)
- Password (text input, obscured, with animated eye icon)
- Re-enter Password (text input, obscured, with animated eye icon)

**Password Rules:**
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 number
- Show rules checklist dynamically as user types (green tick when rule met)

**On Register Button Tap:**
```
Validate locally:
├── Empty fields → show appropriate errors
├── Invalid email format → show error
├── Passwords don't match → show "Passwords do not match"
├── Password rules not met → show which rules failed
└── All valid → send to API

API Response:
├── 201 Created → show "Account created successfully!" toast
│                  → navigate to Login screen (NOT auto-login)
├── 409 Conflict (email exists) → show "Email already registered"
├── 422 Validation Error → show specific validation message
└── Network error → show "Connection error. Please check your internet"
```

**Important:** Registration NEVER auto-logs in the user. Always redirect to Login first.

**Debounce:** Register button disabled for 3 seconds after first tap (longer to prevent duplicate accounts)

**Case-insensitive email:** Store emails as lowercase in database. `User@EMAIL.com` and `user@email.com` are the SAME user.

### Forgot Password Screen

```
User enters email address
→ API sends password reset link/OTP to that email
→ Show "If this email is registered, you'll receive a reset link"
   (Always show this message even if email not found — security practice)
→ Simple OTP/token verification screen
→ New password entry
→ Confirm → navigate to Login
```

### Navigation Rules

```
Auth Landing ──────────────────────→ Login Screen
                                         │
Auth Landing ──────────────────────→ Register Screen
                                         │
Register (success) ────────────────→ Login Screen
Login (success) ────────────────────→ App Home
Auth Landing (Skip) ────────────────→ App Home (as Guest)

Back Navigation:
Login ←─────────────────────────── Auth Landing
Register ←──────────────────────── Auth Landing

Secondary Links:
"Already have an account?" on Register → Login
"Register new account" on Login → Register
```

### State/Session Data

```dart
// These are tracked globally in state management:

String? authToken;                 // JWT token (stored in flutter_secure_storage)
UserModel? authenticatedUser;      // User data after login
bool isGuestMode;                  // True if user skipped auth
String? authErrorMessage;          // Current auth error to display
bool isLoading;                    // Is auth request in progress
```

### Social Login Buttons (Dummy Scope)

```
IMPORTANT: Google and Facebook buttons are:
- Rendered visually exactly as designed
- Marked as "Coming Soon" or dimmed/disabled state
- Do NOT trigger any API calls
- Do NOT show any error when tapped (just no action, or brief toast)
```

### Edge Cases

| Edge Case | Behavior |
|-----------|----------|
| Rapid multiple login taps | Debounce; first tap starts request, additional taps ignored |
| Duplicate register submissions | Debounce + loading state prevents double submission |
| Existing email (register) | "Email already registered" shown clearly |
| Same email, different case | Treated as same account (case-insensitive) |
| Password mismatch | Inline error on re-enter field immediately |
| Backend auth failure | Generic error message; log error for debug |
| Network failure | "No internet connection" toast with retry option |
| User navigates away mid-form | Form data preserved when returning via back button |

---

## 16. PHASE 3 — FLIGHT SEARCH FLOW

### Purpose

The core feature of FLIGHTLY. Users define their trip (origin, destination, dates, passengers,
cabin class) and trigger a flight search.

### Screens

1. Home Search Screen (main landing after login)
2. Airport Search Popup (modal bottom sheet)
3. Date Selection Screen (calendar)
4. Passenger & Class Popup (modal bottom sheet)

### Airport Search Popup

**Trigger:** User taps "From" or "To" field

**Search Capabilities:**
- By IATA code (3 letters, e.g., "CAI" → Cairo International Airport)
- By airport name (e.g., "Heathrow")
- By city name (e.g., "London")
- By country/capital name (e.g., "Egypt" → shows Egyptian airports)

**Behavior:**
```
Before user types:
└── Show recent/history airports (last 5 searched)

As user types:
└── Dynamic autocomplete results update in real-time (debounced 300ms)
    └── Show matching airports in a scrollable list

On airport selection:
└── Close popup
└── Populate corresponding field (From or To)
└── Airport can be edited by tapping field again
```

**Swap Button:**
- Tapping swap icon exchanges origin and destination values
- Animate the swap with a brief rotation/transition effect

**Validation:**
- Origin and destination CANNOT be the same airport
- Show error: "Origin and destination cannot be the same"

**Empty State:**
- When search returns no results: show "No airports found for '[query]'"

### Date Selection Screen

**One-Way Trip:**
- Show single calendar
- User selects departure date only
- Past dates are grayed out and not selectable

**Round-Trip:**
- Show calendar with range selection
- Step 1: User taps departure date (highlighted)
- Step 2: User taps return date (range highlighted between the two dates)
- Range is visually highlighted in calendar

**Validation:**
- Return date cannot be before or same as departure date
- Past dates are disabled (not selectable)

**Trip Type Change Logic:**
```
If user switches Return → One Way AFTER selecting both dates:
└── Return date is cleared and removed
└── Calendar reverts to single-date selection mode

If user switches One Way → Return AFTER selecting departure date:
└── Departure date is preserved
└── Calendar prompts user to select return date
```

**After Selection:**
- Date(s) populate the home search form
- Visually show selected dates as formatted string (e.g., "15 Jan – 22 Jan")

### Passenger & Class Popup

**Passenger Types:**
- Adults (age 12+) — minimum 1 required
- Children (ages 5-14, configurable) — requires adult accompaniment
- Infants (under 2) — requires adult accompaniment

**Ratio Rules:**
```
Ratio: 1 adult can accompany up to 1 child AND 1 infant
Examples:
• 1 adult → max 1 child + 1 infant
• 2 adults → max 2 children + 2 infants
• 0 adults → 0 children, 0 infants allowed (error)

Maximum total passengers = 8
Minimum total passengers = 1 (at least 1 adult)
```

**Cabin Class Options (single-select):**
- Economy
- Premium Economy
- Business
- First Class

**UI Behavior:**
- Plus (+) and minus (-) buttons for each passenger type
- Count cannot go below 0
- Counts dynamically validate ratio rules
- Invalid states show inline warning message
- Done/Confirm button updates the home screen summary

**Home Screen Summary:**
Shows: "2 Adults, 1 Child · Economy" or "1 Adult · Business"

### Search Button Logic

```
On "Search" tap:
Validate:
├── Origin selected? → if not: "Please select your origin"
├── Destination selected? → if not: "Please select your destination"
├── Departure date selected? → if not: "Please select a travel date"
├── Return date selected (if round-trip)? → if not: "Please select return date"
├── Passenger ratio valid? → if not: show ratio error
└── All valid:
    └── Show loading state (search in progress)
    └── Make API call to flight-service
    └── Navigate to Results screen with data
    └── Show error if API fails
```

**Debounce:** Search button disabled for 1 second after tap to prevent rapid multiple requests

### Search State Persistence

```
VERY IMPORTANT:
When user navigates back from Results screen to Home screen:
└── All previously entered values MUST be preserved
    • Origin airport
    • Destination airport
    • Selected dates
    • Trip type (one-way/round)
    • Passenger counts
    • Cabin class
```

### Search History

- Store last 10 unique searches in local device storage
- Show in airport search popup as "Recent Searches" before user types
- Tap recent search → auto-fill that airport

### Search State Object (Passed to Results)

```dart
class SearchQuery {
  final Airport origin;
  final Airport destination;
  final DateTime departureDate;
  final DateTime? returnDate;       // null if one-way
  final TripType tripType;          // oneWay | roundTrip
  final int adults;
  final int children;
  final int infants;
  final CabinClass cabinClass;
}
```

### Edge Cases

| Edge Case | Behavior |
|-----------|----------|
| No airport results found | "No airports found" empty state in popup |
| Same origin and destination | Inline error; prevent search |
| Change trip type after dates selected | Handle date state correctly per rules above |
| User clears passenger counts | Default back to 1 adult minimum |
| Search tapped with incomplete form | Show all relevant validation errors at once |
| Rapid multiple search taps | Debounce 1 second |
| Child-only or infant-only booking | Block and show ratio error |
| Exceed adult ratio | Show "Each adult can accompany max 1 child and 1 infant" |
| Exceed passenger limit | Show "Maximum 8 passengers per booking" |
| No internet when searching | Show "No internet connection" with retry |

---

## 17. PHASE 4 — FLIGHT RESULTS, FILTERING & SORTING

### Results Screen

**Display:**
- List of matching flights as scrollable cards
- Default sort: Best price on first load
- Show "Best", "Cheapest", "Fastest" label badges on relevant cards
- Show airline logo + name, price, departure/arrival times, duration, stops/layovers

**Flight Card Interaction:**
```
First tap on flight card:
└── Expand card to show more details (fare breakdown, baggage preview)

Tap on expanded card area OR "View Details" button:
└── Navigate to Flight Details screen
```

**Pagination:**
- Implement infinite scroll (load more flights as user scrolls to bottom)
- Show loading spinner at bottom while fetching next page

**No Results:**
```
If no flights found for criteria:
├── Show "No Flights Found" screen with illustration
├── Show message explaining criteria used
├── Offer options:
│   • "Modify Search" → go back to search form (preserve values)
│   • "Change Dates" → open calendar directly
│   • "Try Nearby Dates" → show ±3 days price calendar (nice-to-have)
```

### Filtering

**Filter Screen (opened via filter icon top-right):**

**Available Filters:**
1. **Stops:** Non-stop, 1 stop, 2+ stops (checkboxes, multi-select)
2. **Price Range:** Slider, min to max of current results
3. **Duration:** Slider, min to max of current results
4. **Departure Time:** Morning / Afternoon / Evening / Night (toggles)
5. **Arrival Time:** Morning / Afternoon / Evening / Night (toggles)
6. **Return Time:** Morning / Afternoon / Evening / Night (toggles, only if round-trip)
7. **Carriers/Airlines:** Navigate to Carriers sub-screen (multi-select)
8. **Class:** Navigate to Class sub-screen (single-select)

**Critical Filter Rule:**
```
Filters NEVER update results in real-time while adjusting.
Changes only apply when user taps "Apply" button.
This prevents performance issues and confusing flickering.
```

**Filter State Persistence:**
```
When user reopens filter screen after applying:
└── Previously selected filters are shown as-is
```

**Filter Summary on Filter Screen:**
```
After returning from Carriers sub-screen:
└── "Carriers" row shows selected airlines: "EgyptAir, Emirates"
    (instead of generic "Any")

After returning from Class sub-screen:
└── "Class" row shows selected class: "Economy"
    (instead of generic label)
```

**Apply/Reset:**
- Apply → return to results, re-render filtered list
- Reset/Clear → restore all filters to default, show original results
- Leaving filter screen without Apply → discard changes (prompt if any changes made)

### Sorting

**Sort Options:**
- Best (default — balance of price and duration)
- Cheapest (ascending by price)
- Fastest (ascending by duration)
- Earliest Departure
- Latest Departure
- Earliest Arrival

**Sort UI:**
- Sort options visible as horizontal pill/chip selectors at top of results
- Selected sort highlighted
- Results re-sort immediately when sort option changes (sort is instant, unlike filter)

### State Preserved After Filtering/Sorting

```
When user navigates to Flight Details and comes back to Results:
└── Scroll position preserved (user is at same position in list)
└── Applied filters preserved
└── Selected sort preserved
```

### Edge Cases

| Edge Case | Behavior |
|-----------|----------|
| Filters produce no results | Show "No flights match your filters" + "Clear Filters" button |
| Contradictory filters | Apply and show 0 results with guidance to relax filters |
| Leave filter without applying | Discard changes silently (no prompt needed for minor UX) |
| Clearing filters | Restores original unfiltered results |
| API returns partial results | Show what's available, note "Showing X of Y results" |
| Price changes in results | Show price change indicator (up/down arrow with percentage) |

---

## 18. PHASE 5 — FLIGHT DETAILS & SMART PRICING

### Flight Details Screen

**Content Displayed:**

**Outbound Flight:**
- Departure airport, city, time
- Arrival airport, city, time  
- Airline name + logo
- Flight number
- Duration
- Aircraft type (if available)
- Cabin class

**Layover Details (if applicable):**
- Layover airport
- Layover duration
- Terminal information (if available)

**Return Flight (if round-trip):**
- Same structure as outbound flight

**Fare Information:**
- Total price breakdown (per adult, per child, taxes)
- Fare class (Economy Saver / Economy Flex / Business, etc.)
- Fare conditions (non-refundable? changeable?)
- Baggage allowance:
  - Cabin baggage (dimensions + weight)
  - Checked baggage (pieces + weight, or "not included")
- Refund policy
- Change/modification policy

**Seat Availability:**
- "X seats remaining at this price" (urgency indicator if < 5 seats)

**Action Buttons:**
- **Book Now** → proceed to Booking flow
- **Save / Unsave** (heart/bookmark icon) → add/remove from Watchlist

### Smart Pricing System

**Labels Applied to Flight Cards and Details:**
- 🏆 **Best** — Balanced score of price + duration + convenience
- 💰 **Cheapest** — Lowest price option in results
- ⚡ **Fastest** — Shortest total travel time
- 🎯 **Value** — Best price-to-duration ratio

**Price Change Indicators:**
- Green arrow up + percentage: price increased since last viewed
- Green arrow down + percentage: price decreased since last viewed
- Shown on cards in results list

**Dynamic Pricing Logic:**
```
Pricing is simulated in backend using these rules:
• Base price varies by route distance
• Price increases as departure date approaches (last-minute premium)
• Price varies by cabin class multiplier
• Weekend flights cost more than weekdays
• Prices fluctuate ±10% randomly to simulate real dynamic pricing
```

### Book Now Logic

```
User taps "Book Now":
└── Check if price has changed since page loaded (compare cached vs current)
    ├── Price same → pass flight data to Booking flow
    └── Price changed → show dialog: "Price has updated to [new price]. Continue?"
        ├── Accept → proceed to Booking
        └── Decline → stay on details screen
```

### Edge Cases

| Edge Case | Behavior |
|-----------|----------|
| Price changed after selecting | Prompt to accept updated fare (per Book Now logic) |
| Flight became unavailable | Show "This flight is no longer available" + "Search Again" |
| Empty/partial segment data | Show available data; hide empty sections gracefully |
| Saved flight state | Toggle between saved/unsaved immediately (optimistic UI) |

---

## 19. PHASE 6 — BOOKING & RESERVATION FLOW

### Booking Flow Screens (in order)

1. Booking Screen (trip summary + add passengers)
2. Passengers Screen (select/add passengers)
3. Add/Edit Passenger Screen (form)
4. Date of Birth Picker (wheel popup)
5. Nationality Selector (list popup)
6. Overview Screen (full booking review)
7. (→ Payment Phase)
8. (→ Confirmation Phase)

### Booking Screen

**Displayed:**
- Selected flight summary (route, dates, airline, price)
- "Add Passenger" button for each passenger slot
- Contact details section (email, phone)
- Price breakdown (updates dynamically as passengers are added)
- "Continue" / "Proceed to Overview" button

**Validation before proceeding:**
- All passenger slots must be filled
- Contact email: valid format
- Contact phone: valid format
- All passenger details must be complete

### Passengers Screen

**Displayed:**
- List of saved passenger profiles for this user
- "Add New Passenger" button at top/bottom

**Behavior:**
```
User selects existing passenger:
└── Checkmark appears on selected passenger
└── Multiple selection enabled (if booking needs multiple passengers)

User taps edit icon on saved passenger:
└── Navigate to Edit Passenger Screen (same form as Add)
└── Pre-populated with existing data
└── On Done: save changes, return to Passengers screen

User taps "Add New Passenger":
└── Navigate to Add New Passenger form
└── On Done: new passenger saved + shown in list + auto-selected
└── Return to Passengers screen

User taps "Done/Confirm" on Passengers screen:
└── Selected passengers returned to Booking screen
```

### Add / Edit Passenger Form

**Fields:**
- Full Name (text input)
- Gender (radio: Male / Female)
- Date of Birth (tap to open wheel picker)
- Nationality (tap to open nationality selector)
- Passport/ID Number (text input)

**Date of Birth Wheel Picker:**
- Three columns: Day | Month | Year
- Scrollable (iOS-style wheel picker)
- Year range: Current year - 100 → Current year
- Confirm button returns value to form field

**Nationality Selector:**
- Searchable list of all countries
- Alphabetically sorted
- Search by country name
- Tap country to select
- Confirm returns value to form field

**Validation:**
- Full Name: required, minimum 2 characters
- Gender: required
- Date of Birth: required, cannot be future date, must match passenger type age range
- Nationality: required
- Passport Number: required, valid format (alphanumeric, 6-12 characters)
- Passport numbers must be UNIQUE within a booking (no duplicate passports)

### Booking Reference Generation

```javascript
// Format: FLY-YYYYMMDD-XXXXXX (X = random alphanumeric)
// Example: FLY-20250415-A3K9MP

function generateBookingReference() {
  const date = new Date().toISOString().split('T')[0].replace(/-/g, '');
  const random = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `FLY-${date}-${random}`;
}
```

### Overview Screen

**Full Review Before Payment:**
- Flight itinerary (full details)
- All passenger details
- Contact information
- Price breakdown (base fare + taxes + fees = total)
- Terms acceptance checkbox
- "Proceed to Payment" button

**User can still go back to edit** any section from overview.

### Edge Cases

| Edge Case | Behavior |
|-----------|----------|
| Passenger added but not selected | Show "Please select all required passengers" |
| Missing contact info | Show inline validation error |
| Duplicate passport number | "Passport number already added to this booking" error |
| Required fields missing | Prevent proceeding; highlight empty fields |
| User leaves mid-flow | On return: prompt "Resume your booking?" or discard |
| Price changes between overview and payment | Show updated fare dialog (same as details screen logic) |

### Booking State Object

```dart
class BookingModel {
  final String bookingReferenceId;
  final FlightModel selectedFlight;
  final List<PassengerModel> passengers;
  final String contactEmail;
  final String contactPhone;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final PricingBreakdown pricing;
  final DateTime createdAt;
}
```

---

## 20. PHASE 7 — PAYMENT FLOW (DUMMY SCOPE)

### IMPORTANT SCOPE NOTE

```
⚠️  PAYMENT IS DUMMY/SIMULATED IN CURRENT SCOPE  ⚠️

Real payment gateway (Stripe, PayPal, etc.) = FUTURE enhancement
Current implementation is UI-only with simulated payment behavior.
Do NOT build real payment gateway integration.
```

### Payment Screen

**Fields (UI only, no real validation against payment networks):**
- Card Number (16 digits, format: XXXX XXXX XXXX XXXX)
- Cardholder Name
- Expiry Date (MM/YY)
- CVV (3-4 digits)

**Basic client-side validation:**
- Card number: exactly 16 digits
- Name: non-empty
- Expiry: valid MM/YY format, not expired
- CVV: 3-4 digits

**Pay Now Button:**
- Disabled while processing (prevent duplicate taps)
- Shows loading spinner after tap
- 2-second simulated delay to mimic payment processing
- Then: navigate to Confirmation screen (success)

**Simulated Payment Failure (Optional — for testing):**
- If card number starts with "0000": simulate payment failure
- Show payment failure state with retry option

### Confirmation Screen

**Display:**
- ✅ Large success animation
- Confetti celebration effect (3-4 seconds)
- Booking reference number (large, bold, copyable)
- "Booking Confirmed" message
- Complete itinerary summary
- All passenger names
- Total amount paid
- "Download Ticket" button (dummy — shows toast "Feature coming soon")
- "Go to My Trips" button → navigate to My Trips screen
- "Go Home" button → navigate to Home screen

**Data Persistence:**
```
Confirmed booking is IMMEDIATELY saved to database.
It will appear in My Trips → Upcoming Trips tab.
It persists across app restarts and re-logins.
```

---

## 21. PHASE 8 — NOTIFICATIONS & ALERTS

### Notification Types

| Type | When Triggered | Delivery Method |
|------|---------------|-----------------|
| Booking Confirmation | After successful booking | Push + In-app |
| Schedule Update | When flight time changes (simulated) | Push + In-app |
| Price Alert | When watched flight price drops | Push + In-app |
| Fare Change Alert | When fare type changes | In-app |
| General Announcements | App updates, promotions | In-app |

### Push Notifications Setup

- Use Firebase Cloud Messaging (FCM)
- Firebase project must be set up with `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- FCM token retrieved on app launch and stored in User Service
- Push notifications sent from Notification Service backend

### In-App Notifications Screen

**Populated State:**
- List of notifications sorted by date (newest first)
- Unread notifications: highlighted/bold
- Read notifications: normal weight
- Notification icon matches type (plane for booking, bell for alert, etc.)
- Time ago indicator ("2 hours ago", "3 days ago")

**Actions:**
- Tap notification → navigate to relevant screen (booking details, flight details)
- Swipe to dismiss
- "Mark all as read" button
- Long press → "Delete notification" option

**Notification Badge:**
- Red dot/number badge on notification icon in nav bar
- Updates in real-time
- Clears when notification screen is visited

**Empty State:**
- Illustration + "No notifications yet"

### Notification Preferences (In Settings)

```dart
class NotificationPreferences {
  bool bookingConfirmations = true;
  bool scheduleUpdates = true;
  bool priceAlerts = true;
  bool fareChanges = false;
  bool promotions = false;
}
```
Settings toggles map to these preferences. Respect these when sending notifications.

---

## 22. PHASE 9 — SAVED FLIGHTS / WATCH FLOW

### Purpose

Personal flight watchlist — users save flights they're interested in and monitor them
for price changes or to re-search later.

### Watch Tab (Bottom Navigation)

**Populated State:**
Each saved flight card shows:
- Route (Origin → Destination)
- Selected travel dates
- Airline name + logo
- Fare snapshot (price at time of saving)
- Date saved indicator

**Empty State:**
- Illustration + "No saved flights yet"
- "Search for flights" call-to-action button → navigate to Home Search

### Saving a Flight

```
User taps Save/Heart icon on Flight Details screen:
├── Flight NOT yet saved:
│   └── Add to watchlist
│   └── Show success toast: "Flight saved to watchlist"
│   └── Icon changes to filled/active state
│
└── Flight ALREADY saved:
    └── Show toast: "Flight already in your watchlist"
    └── (Do not duplicate)
```

### Saved Flight Interaction

**Tap saved flight card:**
```
→ Re-run new search using saved flight criteria
  (same origin, destination, dates, passengers, class)
→ Navigate to Results screen with fresh results
```

**Three-dot menu on saved flight card:**
- "View Details" → re-search and go to closest matching flight details
- "Remove from Watchlist" → delete with confirmation: "Remove this flight from your watchlist?" → Yes/No
  - On Yes: card immediately removed from list (optimistic update)

### State Persistence

- Watchlist is stored in the database (tied to user account)
- Survives app restart and logout/re-login
- Guest users CANNOT use watchlist (prompt to log in)

### Edge Cases

| Edge Case | Behavior |
|-----------|----------|
| No saved flights | Empty state with illustration and CTA |
| Duplicate save attempt | "Already in watchlist" toast, no duplicate added |
| Saved flight no longer exists | Show card with "Flight no longer available" badge |
| Saved flight price changed | Show new price with "Price changed" indicator vs. snapshot |
| Watchlist accessed as guest | Show "Log in to save flights" prompt |

### Saved Flight Data Model

```dart
class SavedFlightModel {
  final String savedFlightId;
  final String userId;
  final Airport origin;
  final Airport destination;
  final DateTime travelDate;
  final DateTime? returnDate;
  final TripType tripType;
  final CabinClass cabinClass;
  final int adults;
  final int children;
  final int infants;
  final double fareSnapshot;        // Price at time of saving
  final String airlineName;
  final DateTime dateSaved;
}
```

---

## 23. PHASE 10 — MY TRIPS FLOW

### Purpose

Displays all past and upcoming booked trips for the authenticated user.
Acts as a digital travel history and upcoming itinerary manager.

### Screen Structure

**Two tabs:**
1. **Upcoming** — Future booked trips (travel date is in the future)
2. **History** — Past completed trips (travel date has passed)

**Tab switching:** Smooth tab indicator animation, no page reload

### Upcoming Trips

**Trip Card Displays:**
- Route: Cairo → Dubai (with small flag icons)
- Flight date
- Airline name + logo
- Departure time → Arrival time
- Booking reference number
- Status badge: "Confirmed"

**Tap trip card:**
→ Open full booking details screen (same confirmation screen, but in view-only mode)

**Data population:**
```
Completed bookings (from Payment → Confirmation) automatically appear here.
Bookings persist across sessions.
```

### History Trips

**Trip Card Displays:**
- Same as Upcoming but with "Completed" status badge
- Slightly de-emphasized style (grayed slightly)

**Trip card tap:**
→ Open historical booking details (view-only)

### Trip Status Transition Logic

```
IMPORTANT BACKGROUND LOGIC:
Every time the My Trips screen loads, check all upcoming trips:
└── If travel date has passed:
    └── Move trip from Upcoming list to History list
    └── Update status in database from "upcoming" to "completed"
```

### Empty States

- **No Upcoming Trips:** Illustration of luggage + "No upcoming trips" + "Search for flights" CTA
- **No History:** Illustration of map + "No trips yet. Start exploring!" + "Search for flights" CTA

### Edge Cases

| Edge Case | Behavior |
|-----------|----------|
| No upcoming trips | Show empty state with illustration |
| No trip history | Show empty state with illustration |
| Duplicate bookings | Should never appear — prevent at booking creation |
| Past trip not moved to history | Handle in screen load logic (check dates on mount) |

### Future Scope Note

```
// FUTURE ENHANCEMENT (not in current scope):
// Trip cards will support modify/cancel actions
// This will connect to airline API for actual modification
// Currently no modify/cancel functionality is implemented
```

---

## 24. PHASE 11 — ACCOUNT & PROFILE MANAGEMENT

### Account Hub Screen

Central menu navigating to:
- Profile
- My Bookings (→ My Trips flow)
- Passengers (passenger management)
- My Cards (dummy)
- Saved Flights (→ Watch flow)
- Settings

**Rule:** Every single menu item must be navigable. No dead ends.

### Profile Screen

**Displays:**
- Profile photo (circular avatar with camera overlay for edit)
- Display name
- Email address
- Phone number
- Nationality

**Editable Fields:**
- Profile photo: tap → image_picker → select from gallery or camera
- Name: tap → edit inline or navigate to edit screen
- Nationality: tap → nationality selector
- Email: tap → edit with validation
- Phone: tap → edit with phone format validation

**Non-Editable Display (dummy):**
- Linked accounts (Google, Facebook icons — dummy display only)

**Dangerous Actions:**
- **Reset Password** → navigate to Change Password flow
- **Delete Account** → dummy placeholder (show "Feature coming soon")
- **Sign Out** → red button → confirmation dialog: "Are you sure you want to sign out?" → Yes/No

**Persistence:**
Profile changes are saved to the database and persist across sessions.

### Change Password Flow

```
Screen: Change Password
Fields:
• Current Password
• New Password
• Confirm New Password

Validation:
├── Current password: verify against stored password (API call)
├── New password: meets password rules (same as registration)
├── New passwords match: both new password fields identical
└── New password: must be different from current password

On Success:
└── Show "Password updated successfully" toast
└── Navigate back to Profile

On Failure:
└── "Current password is incorrect" error
```

### Passengers Management (Account Level)

Full CRUD for saved passenger profiles:

**List Screen:**
- All saved passengers
- Name, nationality, passport number (masked) shown
- Edit icon beside each passenger
- Swipe-to-delete OR delete icon

**Add Passenger:**
- Same form as Booking → Add Passenger
- Same validation rules

**Edit Passenger:**
- Pre-populated form
- Same validation rules

**Delete Passenger:**
- Confirmation dialog: "Delete [Passenger Name] from your saved passengers?"
- On confirm: remove from database, update list immediately

### My Cards (Dummy Scope)

```
⚠️ DUMMY SCOPE — UI ONLY ⚠️
• Display screen showing "No saved cards" empty state
• "Add Card" button shows "Feature coming soon" toast
• No actual card data stored or processed
• No payment gateway integration
```

### Settings Screen

**Options:**
- **Language:** UI selector showing language options (English, Arabic, etc.)
  - Selecting shows a toast "Full multilingual support coming soon"
  - Store selection but no actual translation implemented
- **Country/Region:** Select country from list, store in preferences
- **Notifications:** Toggle switches for each notification type (maps to Phase 8 preferences)
  - Booking Confirmations: toggle
  - Schedule Updates: toggle
  - Price Alerts: toggle
  - Promotional: toggle

**Persistence:**
All settings persist after app restart using SharedPreferences.

### Edge Cases

| Edge Case | Behavior |
|-----------|----------|
| Invalid profile email format | Show inline validation error |
| Invalid phone format | Show inline validation error |
| Password reset with wrong current password | "Current password is incorrect" error |
| Sign out with unsaved edits | Show "You have unsaved changes. Save or discard?" dialog |
| Delete passenger | Confirmation dialog always required |

### Future Scope Note

```
// FUTURE ENHANCEMENTS (not in current scope):
// • Full multilingual translation (currently UI-only selector)
// • Real card management with payment gateway
// • Account deletion (currently dummy)
// • Social login connection (Google/Facebook)
```

---

## 25. PHASE 12 — SYSTEM STATES & FEEDBACK HANDLING

### Every Screen Must Handle These States

| State | When | UI Treatment |
|-------|------|-------------|
| Loading | Data is being fetched | Shimmer skeleton (lists) or spinner (actions) |
| Empty | No data exists | Illustration + message + CTA |
| Error | Request failed | Error illustration + message + Retry button |
| Offline | No internet connection | Banner/overlay + Retry when connected |
| Partial Failure | Some data loaded, some failed | Show loaded data, indicate what failed |
| Success | Action completed | Toast notification (green) |
| Retry | User attempts again | Trigger same request, reset to Loading state |

### Shimmer Skeleton Implementation

Use the `shimmer` package to create placeholder loading cards that match the shape of
the actual content cards. This prevents layout shift when content loads.

```dart
// Example: ShimmerFlightCard widget shows while real flight cards load
// Must match exact dimensions of real FlightCard widget
```

### Global Loading Indicator

- Thin progress bar at very top of screen (similar to YouTube's red progress bar)
- Appears during any API call
- Disappears when call completes (success or error)
- Non-intrusive: does not block UI interaction

### Toast Notification Usage

```dart
// Success: Green background, checkmark icon, slide-in from top
showSuccessToast("Booking confirmed!");

// Error: Red background, X icon, shake animation
showErrorToast("Failed to load flights. Please try again.");

// Info: Blue background, info icon
showInfoToast("Flight already in your watchlist");

// Warning: Orange background, warning icon
showWarningToast("Only 3 seats remaining at this price!");
```

### Offline Detection

```dart
// Use 'connectivity_plus' package to detect internet status
// When offline:
// • Show non-intrusive banner at top: "No internet connection"
// • Disable action buttons that require network
// • When back online: banner disappears + optional auto-retry
```

### Timeout Handling

```dart
// All API calls have a 30-second timeout
// After timeout:
// • Show error state with: "Request timed out. Please try again."
// • Show Retry button
// • Retry button resets to loading state and tries again
```

### Empty State Specifications

| Screen | Empty State Message | CTA Button |
|--------|-------------------|------------|
| Search Results (no flights) | "No flights found for your search" | "Modify Search" |
| My Trips — Upcoming | "No upcoming trips" | "Search Flights" |
| My Trips — History | "No past trips yet" | "Search Flights" |
| Saved Flights | "No saved flights" | "Search Flights" |
| Notifications | "No notifications yet" | — |
| Passengers | "No saved passengers" | "Add Passenger" |
| My Cards | "No saved cards" | "Add Card (coming soon)" |

---

## 26. PHASE 13 — UNIT & INTEGRATION TESTING

### IMPORTANT NOTE FOR BEGINNER

```
Testing will be a new concept for you. Do not worry — I will explain everything.

Unit Testing = Testing ONE small piece of code in isolation
Integration Testing = Testing how multiple pieces work TOGETHER

Think of it like this:
• Unit test = Testing if a single LEGO piece has the right shape
• Integration test = Testing if multiple LEGO pieces connect correctly together

We do a small but meaningful set of tests to prove the concept was understood and applied.
```

### What We Will Test

**Backend Unit Tests (Jest — Node.js testing framework):**

```javascript
// Auth Service Tests
✓ Should reject login with empty email
✓ Should reject login with invalid email format
✓ Should reject login with wrong password
✓ Should return JWT token on successful login
✓ Should reject registration with mismatched passwords
✓ Should reject registration with existing email
✓ Should hash password before storing in database

// Flight Service Tests
✓ Should return empty array for invalid search criteria
✓ Should correctly filter flights by stop count
✓ Should correctly sort flights by price (ascending)
✓ Should return cheapest flight label correctly

// Booking Service Tests
✓ Should generate unique booking reference ID
✓ Should reject booking with duplicate passport number
✓ Should reject booking with missing required passenger field
✓ Should calculate correct total price for multiple passengers
```

**Flutter Widget Unit Tests (flutter_test):**

```dart
// Validation Function Tests
✓ Should return error for empty email field
✓ Should return error for invalid email format
✓ Should return null (valid) for correct email format
✓ Should return error for password < 8 characters
✓ Should return error for mismatched passwords

// Widget Render Tests
✓ FlightCard widget renders with correct data
✓ FlightCard shows "Cheapest" badge when applicable
✓ LoadingWidget shows shimmer when isLoading = true
✓ EmptyStateWidget displays correct message
```

**Integration Tests:**

```
Test 1: Full Sign-Up → Login Flow
Steps:
1. POST /auth/register with valid data
2. Verify user created in database
3. POST /auth/login with same credentials
4. Verify JWT token returned
5. Verify token is valid and contains correct user ID

Test 2: Search → Results Flow
Steps:
1. POST /flights/search with valid search criteria
2. Verify results returned in expected format
3. Verify results contain required fields (airline, price, times)
4. GET /flights/:id for first result
5. Verify flight details match

Test 3: Full Booking Flow
Steps:
1. Authenticate user (get token)
2. POST /bookings/create with flight + passenger data
3. Verify booking created in database
4. Verify booking reference ID generated
5. GET /bookings/:id — verify all data correct
6. GET /trips/upcoming — verify booking appears
```

### Testing Tools

- **Jest:** Node.js testing framework (comes with most Node.js setups)
- **Supertest:** Makes HTTP requests in tests without running a real server
- **flutter_test:** Built-in Flutter testing package
- **integration_test:** Flutter package for full app integration tests

### How to Run Tests

```bash
# Backend tests (in each service folder):
npm test

# Flutter tests:
flutter test

# Flutter integration tests:
flutter test integration_test/
```

---

## 27. PHASE 14 — FUTURE / ADVANCED FEATURES (NOT CURRENT SCOPE)

```
⛔ DO NOT IMPLEMENT THESE IN CURRENT SCOPE ⛔
These are documented for awareness and future extensibility.
```

### Feature: AI Travel Assistant / Smart Chatbot

**Description:** A conversational AI assistant that helps users find flights, answers
travel questions, and provides personalized recommendations.

**Why not now:** Requires LLM API integration (OpenAI, etc.) and additional cost.

### Feature: Real Payment Gateway

**Description:** Integration with Stripe, PayPal, or regional payment provider for
actual payment processing.

**Why not now:** Requires merchant account, PCI compliance, and payment provider approval.

### Feature: Ticket Modification & Cancellation

**Description:** Allow users to modify booking dates or cancel bookings from the app.
Would connect to airline reservation systems.

**Connection point in app:** My Trips cards will later support modify/cancel actions.

**Why not now:** Requires airline API integration (Amadeus, Sabre, etc.).

### Feature: Full Multilingual Support

**Description:** Complete Arabic language support with RTL layout changes, and other
languages.

**Why not now:** Requires full translation strings for every UI element and RTL layout
adjustments throughout the entire app.

### Feature: Loyalty Program Integration

**Description:** Link frequent flyer accounts, earn and redeem miles.

**Why not now:** Requires individual airline loyalty API partnerships.

### Feature: Multi-City Planner

**Description:** Book complex itineraries with 3+ city stops in a single booking.

**Why not now:** Complex search logic and significantly more complex booking flow.

---

## 28. CORE DATA MODELS

### Flight Model

```dart
class FlightModel {
  final String flightId;
  final String airline;
  final String airlineCode;
  final String airlineLogoUrl;
  final String flightNumber;
  final Airport origin;
  final Airport destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final Duration totalDuration;
  final int stops;                          // 0 = non-stop
  final List<LayoverModel> layovers;        // empty if non-stop
  final List<FlightSegmentModel> segments;
  final FareModel fare;
  final BaggagePolicy baggagePolicy;
  final SeatAvailability seatAvailability;
  final bool isBest;
  final bool isCheapest;
  final bool isFastest;
}
```

### Passenger Model

```dart
class PassengerModel {
  final String passengerId;
  final String userId;                      // owner of this passenger profile
  final String fullName;
  final Gender gender;                      // male | female
  final DateTime dateOfBirth;
  final String nationality;
  final String passportNumber;
  final PassengerType passengerType;        // adult | child | infant
}
```

### Booking Model

```dart
class BookingModel {
  final String bookingReferenceId;          // FLY-YYYYMMDD-XXXXXX
  final String userId;
  final FlightModel selectedFlight;
  final List<PassengerModel> passengers;
  final String contactEmail;
  final String contactPhone;
  final BookingStatus status;               // pending | confirmed | completed | cancelled
  final PaymentStatus paymentStatus;        // pending | paid | failed | refunded
  final PricingBreakdown pricing;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### User Model

```dart
class UserModel {
  final String userId;
  final String email;                       // stored lowercase
  final String displayName;
  final String? profilePhotoUrl;
  final String? phoneNumber;
  final String? nationality;
  final List<PassengerModel> savedPassengers;
  final NotificationPreferences notificationPreferences;
  final UserSettings settings;
  final DateTime createdAt;
}
```

### Saved Flight Model

```dart
class SavedFlightModel {
  final String savedFlightId;
  final String userId;
  final Airport origin;
  final Airport destination;
  final DateTime travelDate;
  final DateTime? returnDate;
  final TripType tripType;
  final CabinClass cabinClass;
  final int adults;
  final int children;
  final int infants;
  final double fareSnapshot;                // price at time of saving
  final String airlineName;
  final String airlineLogoUrl;
  final DateTime dateSaved;
}
```

### Airport Model

```dart
class Airport {
  final String code;                        // IATA code: "CAI"
  final String name;                        // "Cairo International Airport"
  final String city;                        // "Cairo"
  final String country;                     // "Egypt"
  final String countryCode;                 // "EG"
  final double latitude;
  final double longitude;
}
```

---

## 29. GLOBAL APPLICATION STATES

Every screen and feature must handle these states where applicable:

| State | Description | UI Treatment |
|-------|-------------|-------------|
| **Loading** | Async operation in progress | Shimmer skeleton for lists; spinner for actions |
| **Empty** | No data available | Illustration + message + CTA |
| **Error** | Request failed | Error illustration + message + Retry button |
| **Success** | Operation completed | Toast notification |
| **Offline** | No internet connection | Top banner + disabled actions |
| **Retry** | User retrying after error | Reset to loading state, re-trigger request |
| **Partial** | Some data loaded, some failed | Show available data, indicate failures |
| **Stale** | Data is old, needs refresh | Subtle indicator + pull-to-refresh |

---

## 30. API ENDPOINTS REFERENCE

This section is updated after each stage. Here is the planned complete API:

### Auth Service (Port 3001)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | /auth/register | Create new user account | No |
| POST | /auth/login | Login and get JWT token | No |
| POST | /auth/logout | Invalidate session | Yes |
| POST | /auth/forgot-password | Send password reset OTP | No |
| POST | /auth/reset-password | Set new password with token | No |
| POST | /auth/change-password | Change password (logged in) | Yes |
| GET | /auth/verify-token | Validate JWT token | Yes |

### Flight Service (Port 3002)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | /flights/search | Search for flights | No |
| GET | /flights/:id | Get flight details | No |
| GET | /flights/airports/search | Search airports by query | No |
| GET | /flights/airports/popular | Get popular airports | No |

### Booking Service (Port 3003)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | /bookings/create | Create a new booking | Yes |
| GET | /bookings/:id | Get booking by reference | Yes |
| GET | /bookings/user/upcoming | Get user's upcoming trips | Yes |
| GET | /bookings/user/history | Get user's trip history | Yes |

### User Service (Port 3004)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | /users/profile | Get own user profile | Yes |
| PUT | /users/profile | Update own profile | Yes |
| POST | /users/profile/photo | Upload profile photo | Yes |
| GET | /users/passengers | Get saved passengers | Yes |
| POST | /users/passengers | Add new passenger | Yes |
| PUT | /users/passengers/:id | Update passenger | Yes |
| DELETE | /users/passengers/:id | Delete passenger | Yes |
| GET | /users/saved-flights | Get saved/watched flights | Yes |
| POST | /users/saved-flights | Save a flight to watchlist | Yes |
| DELETE | /users/saved-flights/:id | Remove from watchlist | Yes |
| GET | /users/settings | Get user settings | Yes |
| PUT | /users/settings | Update user settings | Yes |

### Notification Service (Port 3005)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | /notifications | Get all notifications for user | Yes |
| PUT | /notifications/:id/read | Mark notification as read | Yes |
| PUT | /notifications/read-all | Mark all as read | Yes |
| DELETE | /notifications/:id | Delete a notification | Yes |
| POST | /notifications/fcm-token | Register FCM device token | Yes |
| PUT | /notifications/preferences | Update notification preferences | Yes |

---

## 31. ENVIRONMENT SETUP REFERENCE

### Required Software (All Free)

| Software | Purpose | Download |
|---------|---------|----------|
| Flutter SDK | Mobile app framework | https://flutter.dev |
| Dart SDK | Comes with Flutter | (included) |
| Node.js (LTS) | Backend runtime | https://nodejs.org |
| Docker Desktop | Container management | https://docker.com |
| PostgreSQL | Primary database | Via Docker (recommended) |
| Redis | Cache/sessions | Via Docker (recommended) |
| Git | Version control | https://git-scm.com |
| VS Code | Code editor | https://code.visualstudio.com |
| Postman | API testing | https://postman.com |
| Android Studio | Android SDK + emulator | https://developer.android.com |

### VS Code Extensions (Recommended)

- Flutter (by Dart Code)
- Dart (by Dart Code)
- REST Client (for API testing)
- Docker (by Microsoft)
- GitLens
- ESLint
- Prettier

### Flutter SDK Verification

```bash
flutter doctor
# This command checks your Flutter setup and tells you what's missing
# All items should show green checkmarks before starting
```

### Starting All Backend Services

```bash
# From project root:
docker-compose up -d
# This starts: PostgreSQL, Redis, all 5 microservices, NGINX
# -d means "detached" (runs in background)

# Check all services are running:
docker-compose ps

# View logs for a specific service:
docker-compose logs auth-service

# Stop all services:
docker-compose down
```

---

## 32. IMPLEMENTED FEATURES LOG (UPDATED PER STAGE)

*This section is updated after each completed and confirmed stage.*

| Stage | Feature | Status | Commit |
|-------|---------|--------|--------|
| 0 | Project Structure & Environment Setup | ⏳ Pending | — |
| 1 | Onboarding Flow | ⏳ Pending | — |
| 2 | Authentication (Sign Up, Login, JWT) | ⏳ Pending | — |
| 3 | Forgot Password | ⏳ Pending | — |
| 4 | Flight Search Screen | ⏳ Pending | — |
| 5 | Airport Search Popup | ⏳ Pending | — |
| 6 | Date Selection Calendar | ⏳ Pending | — |
| 7 | Passenger & Cabin Class Popup | ⏳ Pending | — |
| 8 | Flight Search API (Backend) | ⏳ Pending | — |
| 9 | Flight Results Screen | ⏳ Pending | — |
| 10 | Filter & Sort System | ⏳ Pending | — |
| 11 | Flight Details Screen | ⏳ Pending | — |
| 12 | Smart Pricing Labels | ⏳ Pending | — |
| 13 | Booking Flow (Passenger Selection) | ⏳ Pending | — |
| 14 | Add/Edit Passenger Forms | ⏳ Pending | — |
| 15 | Booking Overview Screen | ⏳ Pending | — |
| 16 | Payment Screen (Dummy) | ⏳ Pending | — |
| 17 | Booking Confirmation + Confetti | ⏳ Pending | — |
| 18 | Push Notifications Setup (FCM) | ⏳ Pending | — |
| 19 | In-App Notifications Screen | ⏳ Pending | — |
| 20 | Saved Flights / Watch Tab | ⏳ Pending | — |
| 21 | My Trips (Upcoming + History) | ⏳ Pending | — |
| 22 | Account Hub & Profile | ⏳ Pending | — |
| 23 | Passengers Management (Account) | ⏳ Pending | — |
| 24 | Settings Screen | ⏳ Pending | — |
| 25 | System States & Loading UX | ⏳ Pending | — |
| 26 | Unit & Integration Tests | ⏳ Pending | — |

---

## FINAL NOTES FOR AI AGENTS

1. **Read this entire file before starting any work.** Do not begin with assumptions.
2. **Current task is always Stage 0** unless the student has confirmed a stage as complete.
3. **Never combine stages.** Each stage = one feature, implemented end-to-end.
4. **Always stop and ask for confirmation** at the end of each stage.
5. **Explain everything** — the student is a beginner. Never assume knowledge.
6. **All errors must be handled** — never leave empty catch blocks.
7. **All code must be complete** — no truncation, no "add the rest here".
8. **Security first** — .env files never committed, passwords always hashed.
9. **Lucide Icons only** — no emojis, no other icon libraries.
10. **Microservices architecture** — each service is independent, has its own folder,
    its own package.json, its own Dockerfile.

---

*CLAUDE.md — FLIGHTLY Master Reference File*
*Generated for Graduation Project — Last Updated: Project Start*
*Update this file after every completed stage.*
