# Consistency Builder

A Flutter productivity app for building daily consistency through tasks, goals, analytics, and achievement tracking.

## Current app flow

- Direct app startup with no login gate
- Home workspace for today's tasks and summary cards
- Progress, goals, analytics, achievement, and edit flows
- Persistent task and goal data saved in local storage for web/native builds

## Run locally

```bash
flutter pub get
flutter run
```

## Build for web

```bash
flutter build web --release
```

## Notes

- The app keeps data across refreshes on web using SharedPreferences.
- Native platforms use SQLite-backed storage for persistence.
- The task model follows a direct, single-user workspace flow rather than a login/register flow.
