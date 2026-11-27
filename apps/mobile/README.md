# lean_tracker

Lean Tracker mobile app (Android and iOS).

## Run

```sh
cp env/example.json env/local.json   # git-ignored; fill SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL
flutter run --dart-define-from-file=env/local.json
```

The local stack (`make up` in the repo root) serves Auth on `:54321` and the emails in Mailpit on `:8025`. On the Android emulator use `10.0.2.2` instead of `127.0.0.1`. Without the three keys the app shows a developer-only configuration screen.

Tools run in Docker through the root `Makefile`: `make lint`, `make test`, `make gen-dart`.
