# IEEE AIUB Student Branch Volunteers Hub

A mobile application designed to simplify volunteer task management, event coordination, announcements, and communication for the **IEEE AIUB Student Branch**.

The platform connects volunteers and executive members through a centralized system, helping the branch organize activities, distribute responsibilities, track progress, and maintain volunteer engagement.

## Table of Contents

* [Overview](#overview)
* [Features](#features)
* [Technology Stack](#technology-stack)
* [System Architecture](#system-architecture)
* [Project Structure](#project-structure)
* [Prerequisites](#prerequisites)
* [Getting Started](#getting-started)
* [Backend Setup](#backend-setup)
* [Flutter App Setup](#flutter-app-setup)
* [Database Setup](#database-setup)
* [API Overview](#api-overview)
* [User Roles](#user-roles)
* [Notifications](#notifications)
* [Development Status](#development-status)
* [Security Notes](#security-notes)
* [Future Improvements](#future-improvements)
* [Contributing](#contributing)
* [License](#license)

## Overview

IEEE AIUB Student Branch Volunteers Hub is a mobile-first platform built to support the day-to-day activities of IEEE AIUB Student Branch.

It provides separate experiences for volunteers and executive members. Executives can assign tasks and manage volunteer responsibilities, while volunteers can view their assignments, update task statuses, and keep track of their activities.

The project uses a centralized backend and database so that users on different devices can access shared information.

## Features

### Authentication and Profiles

* Member ID and password login.
* Volunteer and executive roles.
* User registration.
* Profile viewing and editing.
* Password hashing on the backend.
* Token-based authentication using JWT.

### Task Management

* Executive members can assign tasks to volunteers.
* Tasks include titles, descriptions, priorities, points, teams, and deadlines.
* Volunteers can view their assigned tasks.
* Task status tracking:

  * Pending
  * In Process
  * Done
* View tasks assigned by an executive.
* Track task progress and completed work.

### Event Management

* View upcoming events.
* Create events through the app.
* View event details.
* Access event information from the dashboard.

### Notifications

* View notifications.
* Mark individual notifications as read.
* Mark all notifications as read.
* Delete individual notifications.
* Clear all notifications.
* View unread notification counts.
* Firebase Cloud Messaging integration groundwork for push notifications.

### Dashboards

* Separate volunteer and executive dashboards.
* Dashboard task summaries.
* Quick access to upcoming events and notifications.
* A modern interface with a deep-blue theme.

## Technology Stack

| Component                           | Technology                        |
| ----------------------------------- | --------------------------------- |
| Mobile application                  | Flutter                           |
| Programming language                | Dart                              |
| Backend API                         | ASP.NET Core Web API              |
| Backend language                    | C#                                |
| Framework                           | .NET 9                            |
| Database                            | PostgreSQL                        |
| Database hosting during development | Docker                            |
| Data access                         | Entity Framework Core             |
| Database provider                   | Npgsql                            |
| Authentication                      | JWT Bearer Authentication         |
| Password security                   | PBKDF2 password hashing           |
| API documentation                   | Swagger / OpenAPI                 |
| Push notification infrastructure    | Firebase Cloud Messaging          |
| Local notifications                 | Flutter local notification plugin |
| IDE                                 | Visual Studio Code                |

## System Architecture

The application follows a client-server architecture.

```text
                 ┌──────────────────────────┐
                 │      Flutter App         │
                 │  iOS / Android Devices   │
                 └────────────┬─────────────┘
                              │
                         HTTPS / HTTP
                              │
                 ┌────────────▼─────────────┐
                 │  ASP.NET Core Web API    │
                 │                          │
                 │  Authentication          │
                 │  Task Management         │
                 │  User Management         │
                 │  Notifications           │
                 └────────────┬─────────────┘
                              │
                    Entity Framework Core
                              │
                 ┌────────────▼─────────────┐
                 │       PostgreSQL         │
                 │                          │
                 │  Users                   │
                 │  Tasks                   │
                 │  Notifications           │
                 └──────────────────────────┘

                 Firebase Cloud Messaging
                 (Push notification delivery)
```

The Flutter application communicates with the backend API. The API processes requests and stores shared data in PostgreSQL.

Firebase Cloud Messaging is used as the foundation for delivering push notifications to registered devices.

**Development note:** Local notifications and backend notification records are implemented. Full production-ready push delivery should be verified separately before claiming that every notification is delivered to every device.

## Project Structure

```text
ieee_volunteer_hub/
│
├── lib/
│   ├── main.dart
│   │
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── registration_screen.dart
│   │   ├── registration_success_screen.dart
│   │   ├── volunteer_dashboard.dart
│   │   ├── executive_dashboard.dart
│   │   ├── volunteer_tasks_screen.dart
│   │   ├── volunteer_events_screen.dart
│   │   ├── event_details_screen.dart
│   │   ├── assign_task_screen.dart
│   │   ├── executive_task_details_screen.dart
│   │   ├── create_event_screen.dart
│   │   ├── notifications_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   └── notification_test_screen.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── database_service.dart
│   │   ├── task_service.dart
│   │   ├── fcm_service.dart
│   │   ├── notification_service.dart
│   │   └── central_notification_service.dart
│   │
│   └── firebase_options.dart
│
├── backend/
│   └── IEEEVolunteerHub.Api/
│       ├── Controllers/
│       │   ├── AuthController.cs
│       │   ├── UsersController.cs
│       │   ├── TasksController.cs
│       │   └── NotificationsController.cs
│       │
│       ├── Data/
│       │   └── ApplicationDbContext.cs
│       │
│       ├── DTOs/
│       │
│       ├── Models/
│       │   ├── User.cs
│       │   ├── Task.cs
│       │   └── Notification.cs
│       │
│       ├── Services/
│       │   └── PasswordService.cs
│       │
│       ├── Migrations/
│       ├── Properties/
│       │   └── launchSettings.json
│       ├── appsettings.json
│       ├── appsettings.Development.json
│       ├── Program.cs
│       └── IEEEVolunteerHub.Api.csproj
│
├── android/
├── ios/
├── test/
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

*This structure describes the principal files. Your local repository may contain additional files or folders.*

## Prerequisites

Install the following tools on macOS:

* [Flutter SDK](https://docs.flutter.dev/get-started/install/macos)
* [Dart SDK](https://dart.dev/get-dart) (normally included with Flutter)
* [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
* [Docker Desktop](https://www.docker.com/products/docker-desktop/)
* [Visual Studio Code](https://code.visualstudio.com/)
* [Xcode](https://developer.apple.com/xcode/) for iOS development
* [CocoaPods](https://cocoapods.org/) for iOS dependencies
* [Firebase Console](https://console.firebase.google.com/) for Firebase configuration

Verify the installations:

```bash
flutter doctor
dotnet --version
docker --version
```

## Getting Started

Clone the repository if it is hosted on GitHub:

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd ieee_volunteer_hub
```

If the project is already on your Mac, open its existing folder instead.

## Backend Setup

### 1. Open the backend directory

```bash
cd backend/IEEEVolunteerHub.Api
```

### 2. Configure the database connection

Open `appsettings.json` and configure the PostgreSQL connection string.

The current development configuration uses:

```text
Host=localhost
Port=5433
Database=ieee_volunteer_hub
Username=ieee_admin
```

The development password is configured locally and should not be committed to a public repository. Use environment variables or .NET user secrets for sensitive settings.

### 3. Start PostgreSQL

If the development PostgreSQL container already exists, start it:

```bash
docker start ieee-volunteer-postgres
```

If it does not exist, create a development container:

```bash
docker run --name ieee-volunteer-postgres \
  -e POSTGRES_DB=ieee_volunteer_hub \
  -e POSTGRES_USER=ieee_admin \
  -e POSTGRES_PASSWORD=CHANGE_THIS_PASSWORD \
  -p 5433:5432 \
  -d postgres:17-alpine
```

If you create a new container, update the backend connection string to match its password.

### 4. Restore backend dependencies

```bash
dotnet restore
```

### 5. Apply database migrations

If the Entity Framework CLI is not installed:

```bash
dotnet tool install --global dotnet-ef --version 9.0.9
```

If it is already installed, update it if necessary.

Apply migrations:

```bash
dotnet ef database update
```

### 6. Run the API

```bash
dotnet run
```

The development API is configured to use port `5191` for HTTP. Check the startup output for the actual listening address.

Open Swagger in your browser:

```text
http://localhost:5191/swagger
```

Swagger allows you to inspect and test the available API endpoints.

## Flutter App Setup

### 1. Open the project root

Open a new terminal:

```bash
cd /Users/rafithtarafder/Desktop/ieee_volunteer_hub
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Configure the API address

Open the service files that define the API base URL, including:

* `lib/services/auth_service.dart`
* `lib/services/task_service.dart`
* `lib/services/central_notification_service.dart`

For the iOS simulator, the Mac's `localhost` address may be suitable:

```text
http://localhost:5191/api
```

For a physical iPhone, use your Mac's LAN IP address, for example:

```text
http://192.168.31.187:5191/api
```

Replace the example IP with the current IP address of your Mac. You can check it with:

```bash
ipconfig getifaddr en0
```

Make sure the backend listens on an address reachable from your phone and that both devices are on the same network.

**Important:** Plain HTTP is appropriate only for controlled local development. Production deployments should use HTTPS and a secure public API address.

### 4. Configure Firebase

The project uses Firebase Core and Firebase Messaging.

Ensure that:

* The Firebase project is configured correctly.
* The generated `lib/firebase_options.dart` file is present.
* The iOS app's Firebase configuration file is included in the correct location.
* Android has its required Firebase configuration file.
* Notification permissions are configured for the target platform.

If Firebase configuration needs to be regenerated, follow the official [FlutterFire documentation](https://firebase.google.com/docs/flutter/setup).

### 5. Run the application

List available devices:

```bash
flutter devices
```

Run the app on the selected simulator or connected device:

```bash
flutter run
```

For iOS, open the simulator first if necessary. For a physical iPhone, configure signing and device permissions through Xcode.

## Database Setup

PostgreSQL is the centralized database for the backend.

The primary entities currently include:

| Entity        | Purpose                                                                        |
| ------------- | ------------------------------------------------------------------------------ |
| Users         | Member IDs, profiles, roles, password hashes, and device tokens                |
| Tasks         | Assignments, descriptions, priorities, points, deadlines, and status           |
| Notifications | Recipient, message, read status, timestamps, and related task/event references |

Entity Framework Core migrations maintain the database schema.

Useful development commands:

```bash
dotnet ef migrations list
dotnet ef database update
```

To open the PostgreSQL command-line client inside the running container:

```bash
docker exec -it ieee-volunteer-postgres \
  psql -U ieee_admin -d ieee_volunteer_hub
```

Use `\dt` to list tables and `\q` to exit.

**Warning:** Do not delete the database volume or drop tables unless you intend to lose the stored development data.

## API Overview

The backend exposes REST API endpoints.

| Method | Endpoint                              | Purpose                                          |
| ------ | ------------------------------------- | ------------------------------------------------ |
| POST   | `/api/Auth/register`                  | Register a member                                |
| POST   | `/api/Auth/login`                     | Authenticate a member                            |
| GET    | `/api/Auth/me`                        | Retrieve the authenticated user's profile        |
| POST   | `/api/Auth/fcm-token`                 | Register a device's FCM token                    |
| GET    | `/api/Users/volunteers`               | Retrieve volunteers for authorized executives    |
| GET    | `/api/Users/executives`               | Retrieve executives for authorized executives    |
| GET    | `/api/Users/{memberId}`               | Retrieve a member profile                        |
| POST   | `/api/Tasks`                          | Create and assign a task                         |
| GET    | `/api/Tasks/my-tasks`                 | Retrieve the authenticated volunteer's tasks     |
| GET    | `/api/Tasks/{id}`                     | Retrieve a task                                  |
| PUT    | `/api/Tasks/{id}/status`              | Update task status                               |
| GET    | `/api/Tasks/assigned-by-me`           | Retrieve tasks assigned by the current executive |
| GET    | `/api/Tasks/all`                      | Retrieve all tasks, subject to authorization     |
| GET    | `/api/Notifications/my-notifications` | Retrieve the current member's notifications      |
| GET    | `/api/Notifications/unread-count`     | Retrieve the unread notification count           |
| PUT    | `/api/Notifications/{id}/read`        | Mark a notification as read                      |
| PUT    | `/api/Notifications/read-all`         | Mark all notifications as read                   |
| DELETE | `/api/Notifications/{id}`             | Delete a notification                            |
| DELETE | `/api/Notifications/all`              | Delete all notifications for the current member  |

Use Swagger to verify the actual request and response formats for each endpoint. Authenticated endpoints require a valid JWT bearer token.

## User Roles

### Volunteer

Volunteers can:

* Log in to their account.
* View assigned tasks.
* Update task progress.
* View upcoming events.
* Access notifications.
* View and edit their profile.
* Review their completed work.

### Executive

Executive members can:

* Access the executive dashboard.
* View available volunteers.
* Assign tasks.
* Set task priorities, points, and deadlines.
* Track assigned tasks.
* Create and manage event information.
* Review task progress.

Role-based authorization is enforced by the backend for protected API endpoints.

## Notifications

The project includes both local notification functionality and centralized notification records.

* Local notifications can display notifications on the device.
* Central notification records are stored in PostgreSQL.
* Firebase Cloud Messaging provides the infrastructure for remote push notifications.

For reliable push delivery across multiple physical devices, the production workflow must register and refresh each device's FCM token, store it on the backend, and send push messages from a trusted server environment.

Never embed Firebase service-account credentials in the Flutter application.

## Development Status

The project is under active development.

Implemented areas include:

* Flutter authentication and profile screens.
* Volunteer and executive dashboards.
* Task assignment and status management.
* PostgreSQL-backed API infrastructure.
* JWT authentication and password hashing.
* Central notification endpoints.
* Event-related screens.
* Firebase configuration and messaging integration.

Areas that require continued integration and testing include:

* Consistent notification creation when a task is assigned.
* Reliable login and API connectivity after backend restarts.
* End-to-end synchronization across physical devices.
* Production-ready Firebase push delivery.
* Deployment of the API and database to secure hosting.
* Automated tests, logging, and production configuration.

## Security Notes

Before deploying this project for real users:

1. Do not commit database passwords, JWT signing keys, or Firebase service-account files.
2. Replace development secrets with secure environment-specific configuration.
3. Use HTTPS for all production API traffic.
4. Keep password hashing and JWT validation on the backend.
5. Validate authorization for every user-specific resource.
6. Ensure volunteers cannot modify tasks assigned to other members.
7. Ensure users can only read or delete their own notifications unless an explicit administrative permission allows otherwise.
8. Restrict database access to trusted services.
9. Configure backups and a recovery plan for PostgreSQL.
10. Review logs to ensure that passwords, tokens, and other secrets are never recorded.

## Future Improvements

Potential future enhancements include:

* Reliable real-time push notifications.
* Real-time task updates.
* Event registration and attendance tracking.
* Volunteer points and leaderboards.
* Announcements and branch-wide updates.
* Team-based task assignment.
* Executive reports and volunteer activity analytics.
* Administrative controls and account management.
* Automated testing and continuous integration.
* Production deployment with monitoring and database backups.

## Contributing

Contributions and suggestions are welcome.

1. Create a branch for your change.
2. Keep changes focused and test them locally.
3. Verify both the Flutter app and the backend API where relevant.
4. Submit a pull request describing the change.
   
## 👨‍💻 Author

**Tarafder Md. Rafith**

* GitHub: [@tarafderRafith](https://github.com/tarafderRafith)
## License

No license has been specified yet. Add a `LICENSE` file before distributing or reusing this project publicly.

---

**IEEE AIUB Student Branch Volunteers Hub**
*Connecting volunteers, organizing tasks, and supporting branch activities through technology.*
