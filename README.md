# AlinaNTWork 📅

> Team leave tracker for night shift supervisors — built with Flutter & Firebase.

A mobile app for managing a team's annual leave, sick days, bank holidays, and birthdays. Designed for a single supervisor who previously tracked everything in a paper diary.

---

## Features

- **Calendar** — weekly view showing all leave types and birthdays at a glance
- **Team** — manage employees, track remaining leave days, set birthdays
- **Dashboard** — live overview of who's away, upcoming leave, conflicts, and birthdays
- **Notes** — private supervisor notes, optionally linked to a specific employee
- **Cloud sync** — Firebase Auth + Firestore keeps data safe and restorable
- **Auto-update** — checks GitHub Releases and installs new versions automatically

## Leave Types

| Type | Color | Counts toward 28 days |
|------|-------|----------------------|
| 🌴 Annual Leave | Mint | ✅ Yes |
| 🤒 Sick Leave | Rose | ❌ No |
| 🎂 Birthday Holiday | Purple | ❌ No |
| 🏦 Bank Holiday | Cyan | ✅ Yes |

## Tech Stack

- **Flutter** + Dart
- **Riverpod** — state management
- **Hive** — local storage / offline cache
- **Firebase Auth** — single-user authentication
- **Firestore** — cloud data sync & backup
- **go_router** — navigation
- **GitHub Releases API** — auto-update system

## Project Structure

```
lib/
  models/          # Employee, LeaveRecord, NoteRecord (Hive)
  providers/       # Riverpod state notifiers
  screens/
    auth/          # Login screen
    calendar/      # Weekly grid + leave list
    team/          # Employee cards + add/edit
    dashboard/     # Stats, conflicts, upcoming
    notes/         # Monthly calendar + notes
    settings/      # Account, version, update check
  services/        # Firebase, Firestore, UpdateService, AuthService
  widgets/         # Shared widgets, UpdateBanner
  theme/           # AppColors, AppTheme
```

## Getting Started

1. Clone the repo
2. Run `flutter pub get`
3. Add your own `google-services.json` to `android/app/`
4. Run `flutter pub run build_runner build --delete-conflicting-outputs`
5. `flutter run`

> **Note:** Firebase project and Authentication must be configured separately.  
> This app is designed for a single authenticated user (supervisor only).

## Auto-Update

Releases are distributed via GitHub Releases. The app checks for updates on launch and shows a banner if a new `.apk` is available. Updates are downloaded and installed automatically.

To publish a new version:
1. Bump `version` in `pubspec.yaml` (e.g. `1.0.1+2`)
2. Build: `flutter build apk --release`
3. Create a GitHub Release tagged `vX.X.X`
4. Attach `app-release.apk` as a release asset

---

Built by [Oleg Baikov](https://github.com/obaikov22) · London, 2026
