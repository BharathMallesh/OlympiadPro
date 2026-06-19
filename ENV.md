# Frontend environment (backend URL) — no code edits needed

The app reads `API_BASE_URL` from a JSON env file via Flutter's
`--dart-define-from-file`. Pick the file at build/run time; never edit Dart code.

- `env.dev.json` — local development (`API_BASE_URL` empty → the app auto-uses
  the Android emulator host `10.0.2.2:8090`, or `localhost:8090` elsewhere).
- `env.prod.json` — deployed backend. Set `API_BASE_URL` to your Render URL
  (no trailing slash), e.g. `https://vidyora-backend.onrender.com`.

## Usage
```bash
# Local dev (emulator / device / web)
flutter run --dart-define-from-file=env.dev.json

# Release builds pointing at the deployed backend
flutter build apk     --release --dart-define-from-file=env.prod.json
flutter build appbundle --release --dart-define-from-file=env.prod.json
flutter build ios     --release --dart-define-from-file=env.prod.json
```

## Notes
- **Web doesn't need this** — when `API_BASE_URL` is empty the web build talks to
  the same origin it was served from. So a web build served by the backend just
  works. (You can still set it if hosting the web app on a different domain.)
- Resolution order in `lib/data/api.dart`: `API_BASE_URL` (this file) →
  web same-origin → local emulator/localhost fallback.
- These files hold only a URL (not a secret), so they're safe to commit. Each
  dev can keep their own copy or override the value.
