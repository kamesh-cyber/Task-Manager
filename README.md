# Task Manager App

A cross-platform Flutter application for managing Projects and Tasks with Back4App (Parse Server) as the backend. Built with a clean, light-mode UI inspired by the macOS Notes aesthetic.

---
## Table of Contents
1. Overview
2. Prerequisites
3. Setup & Installation
4. Features
5. Tech Stack
6. Data Models & Backend Schema
7. Project & Task Lifecycle 
8. Authentication Flow 
9. Soft Delete Strategy 
10. Running on Platforms (Mobile / Web / Desktop)

---
## 1. Overview
This app allows authenticated users to:
- Create and manage multiple projects.
- Add tasks within projects.
- Mark tasks as completed (strike-through) or active.
- Soft delete tasks (retain record but hide from active lists).

Designed for extensibility (priority, due dates, collaboration, offline sync can be added later).

---
## 2. Prerequisites
Before installing and running the application ensure you have:
- Flutter SDK (>= 3.7, recommended 3.9+)
- Dart SDK (bundled with Flutter)
- Xcode (for iOS builds) / Android Studio + Android SDK (for Android)
- A Back4App account with an application created
- Valid Back4App Application ID & Client Key
- (Optional) Chrome for web runs

---
## 3. Setup & Installation
```bash
# Clone repository
git clone <repo-url>
cd task_manager_app

# Create .env file (fill with your real credentials)
printf "BACK4APP_APP_ID=xxx\nBACK4APP_CLIENT_KEY=yyy\nBACK4APP_SERVER_URL=https://parseapi.back4app.com\n" > .env

# Install dependencies
flutter pub get

# (Optional) Clean build artifacts
flutter clean && flutter pub get

# Run on a connected device / emulator
flutter run
```
### Updating Dependencies
```bash
flutter pub outdated   # inspect
flutter pub upgrade    # cautious upgrade
```

---
## 4. Features
### User & Auth
- Email + password signup & login (Back4App Parse `_User` class).
- Session persistence and auto-login if session valid.
- Logout & error messaging.

### Projects
- List projects belonging to the logged-in user.
- Create / edit / delete project entries.
- Empty state when no projects exist.

### Tasks
- List tasks scoped to a selected project.
- Create / edit tasks.
- Toggle completion (Boolean) with visual strike-through.
- Soft delete (set `active = false`).
- Refresh indicator & pull-to-refresh.
- Bulk operations possible (extendable later).

---
## 5. Tech Stack
- **Framework:** Flutter (Dart SDK 3.x)
- **Backend:** Back4App (Parse Server SaaS)
- **State Management:** Basic StatefulWidgets (Provider dependency included for future expansion)
- **Packages:**
  - `parse_server_sdk_flutter` – Parse API client
  - `flutter_dotenv` – Environment variable loader
  - `provider` – (Currently unused for global state; reserved for scaling) 
  - `http` – Compatibility dependency for Parse SDK

---
## 7. Data Models & Backend Schema
### Parse Classes
| Class       | Purpose                      | Key Fields                                                                                  |
|-------------|------------------------------|----------------------------------------------------------------------------------------------|
| `_User`     | Authentication               | `username`, `email`, `password`                                                             |
| `Project`   | User project container       | `title` (String, required), `description` (String), `user_id` (Pointer->_User)              |
| `task`      | Individual task item         | `description` (String), `completed` (Boolean, default false), `active` (Boolean, default true), `project_id` (Pointer->Project) |

### Model Mapping Examples
`project.dart` maps ParseObject('Project') fields ⇄ Project(data class). 
`task.dart` maps ParseObject('task') ⇄ Task(data class).
---
## 10. Project & Task Lifecycle
1. **Create Project:** User inputs title/description → `ProjectService.createProject()` → saved to Parse.
2. **List Projects:** Filter by `user_id` pointer.
3. **Open Project:** Navigates to task list screen.
4. **Create Task:** Description only (extendable). Pointer to project.
5. **Complete Task:** Toggle `completed` boolean.
6. **Soft Delete Task:** Sets `active = false`; queries only fetch `active = true`.

---
## 11. Authentication Flow
- **Signup:** Creates `_User` with username, email, password.
- **Login:** Validates credentials; session auto-managed by Parse SDK.
- **Persist Session:** `ParseUser.currentUser()` used to check state at app start.
- **Logout:** Explicit call removes session tokens.

---
## 12. Soft Delete Strategy
Instead of permanent deletion we:
- Mark `active = false` for tasks.
- Query filters only include `active = true`.
Advantages: auditability, future restore feature. To hard-delete you could call `parseObject.delete()`.

---
## 13. Running on Platforms (Mobile / Web / Desktop)
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (Chrome)
flutter run -d chrome

# macOS Desktop
flutter run -d macos

# Windows / Linux (if enabled)
flutter run -d windows
flutter run -d linux
```