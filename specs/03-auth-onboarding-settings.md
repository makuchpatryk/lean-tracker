# Auth, Onboarding and Settings (M2) — Implementation Plan

## Summary
M2 turns the M1 skeleton into a usable account flow. The app gets sign-up and sign-in with email + password, Google and Apple through Supabase Auth, plus an email-confirmation screen and a password-reset flow. It adds a goals gate before the diary and a Settings screen with goals, language and theme info, and sign out. Strings come in PL and EN, and the DESIGN theme follows the system light or dark setting. The API gains a `settings` module (`GET/PUT /v1/settings`). Local dev gets Supabase Auth (GoTrue), an nginx gateway and Mailpit in `compose.yaml`, so the email flows run without a hosted project. Milestone **M2** (PRD §19). Base: `main` at `b59fd19`, clean tree. No unmerged branch is relied on. The stale worktree `.claude/worktrees/01-repo-api-skeleton` is not used.

Facts verified during planning:
- `supabase/postgres:17.12.0.005` ships `auth.users`, `auth.schema_migrations` and the login role `supabase_auth_admin`. That role accepts `POSTGRES_PASSWORD`. So `apps/api/db/local/00_auth_stub.sql` stays a no-op and is not changed, and GoTrue migrates the `auth` schema on top of it.
- `github.com/getkin/kin-openapi` is already in `apps/api/go.mod` (indirect). `yaml` and `intl` are already in `apps/mobile/pubspec.lock` (transitive).
- The main `AndroidManifest.xml` has no `INTERNET` permission (only debug and profile have it). It has no deep-link intent filter. `Info.plist` has no `CFBundleURLTypes`.
- `make lint-dart` formats only `lib/main.dart lib/app test`.
- `.gitignore` already ignores `.cache/` and `apps/mobile/env/*.json`, except `env/example.json`.
- `httpapi.NewHandler` takes `*HealthServer` directly. The generated strict handler uses text/plain default error handlers.

## Success Criteria
- **FR-001, criterion 1 (corrected):** an unregistered email with an 8-character password creates an account and shows the check-email screen.
- **FR-001, criterion 2:** a 7-character password shows "Password must have at least 8 characters." and creates no account.
- **FR-001, criterion 3:** a signed-in user stays signed in after restart. The session is restored from secure storage.
- **Email links:** the confirmation link opens the app through `io.github.example.leantracker://auth-callback`, and the goals gate follows. The reset link opens the new-password screen.
- **FR-002:** kcal 499 shows "Enter a value from 500 to 10000." and nothing is sent. Valid goals saved through `PUT /v1/settings` show in Settings → Goals after restart. The FR-002 Diary criterion holds from M3.
- **BP-006:** a signed-in user with no settings row sees the goals screen. The Diary route is unreachable until four goals are saved.
- **BR-001 and NFR-004:** `GET` and `PUT /v1/settings` without a valid JWT return 401. The repository test proves user A cannot read or overwrite user B's row. `GET` with no row returns 404 `SETTINGS_NOT_FOUND`.
- **Light checks:** `make lint` and `make test` are green, and `make check-contract` passes. The kernel limits equal the contract `minimum`/`maximum` in both apps (AD6).

## Scope & Constraints
- **In scope:**
  - FR-001: email + password, Google, Apple (offered on iOS and Android), password reset by email, session persistence.
  - FR-002, FR-017, UF-001, UF-006 (Goals, Language and theme info row, Sign out), BP-006, BR-001, BR-002, BR-003 (goal ranges), NFR-004.
  - Contract: `GET/PUT /v1/settings` and new error codes.
  - Go: module `settings`, `kernel/limits`, `kernel/clock`, router and wiring.
  - Compose: `auth` (GoTrue), `auth-gateway` (nginx), `mailpit`. Makefile changes.
  - Mobile: modules `auth` and `settings`, `kernel/limits`, `ui/` theme with Nunito, ARB l10n, go_router guard, a Diary placeholder, a 2-tab bottom bar, deep links.
  - Docs: PRD, ARCHITECTURE, README.
- **Out of scope:**
  - Settings rows Reminders and Delete account (M7).
  - Diary content, Drift and local goals cache (M3). Products (M4). Weekly tab (M5). Sync (M6).
  - Consent screen and analytics (§23). Manual theme or language switch (§10.3).
  - Native Google/Apple SDKs.
  - Hosted Supabase setup, deploy, hosted migrations (user actions, M8).
  - Integration tests (`lean-e2e` only).
- **Hard constraints:**
  - BR-001: every settings query filters by `user_id` from the JWT `sub`.
  - BR-003: kcal is an integer from 500 to 10000; protein, fat and carbs are integers from 0 to 1000. These are mirrored in both `kernel/limits` files.
  - NFR-004: the app holds only `SUPABASE_URL` and `SUPABASE_ANON_KEY`, plus the non-secret `API_BASE_URL`. No service role key exists anywhere.
  - D-65: the API accepts only ES256/RS256 tokens. Local GoTrue signs with an ES256 key and serves JWKS.
  - D-64: generated code is never edited. D-66: tools run in Docker through the Makefile.
  - ARCHITECTURE: Supabase, Dio and `lib/gen` appear only in mobile `infrastructure` (and `app/`). SQL appears only in Go `infrastructure`.
  - §16: 360 dp, font scale up to 200%, `Semantics` on interactive elements, contrast ≥ 4.5:1.
  - §11 texts beat DESIGN texts. DESIGN wins on layout. Where §11 has no text, the DESIGN text is used.
- **Trade-offs:**
  - Goals are API-only, so the goals gate and Settings need network in M2. Owner choice. M3 adds Drift.
  - Local GoTrue + gateway + Mailpit: three extra containers on every `make up`, in exchange for a full email flow without a hosted project. Owner choice.
  - Browser OAuth over native SDKs: no extra packages, one code path. The OAuth sheet is a browser, not native.
  - Email confirmation on: one more screen, and Supabase hides "already registered" (see Risks).
  - Generic error codes, reusable by later routes. Owner choice.

## Architecture & Design

### High-Level Flow
```
Mobile                                                       API
main.dart -> app/bootstrap (config check, Supabase.initialize PKCE + secure LocalStorage)
app/router  redirect = route_guard.redirectFor(authStatus, goalsStatus, location)
  /login /check-email /forgot-password /new-password  -> auth use cases -> AuthGateway port
        -> SupabaseAuthGateway (supabase_flutter) -> GoTrue (local via auth-gateway :54321/auth/v1, hosted *.supabase.co/auth/v1)
  /goals /settings /settings/goals -> settings use cases -> GoalsRepository port
        -> ApiGoalsRepository (lib/gen RestClient, Dio + Bearer) -> GET/PUT /v1/settings
                                                              jwtauth.Middleware (JWKS, sub -> context)
                                                              -> strict handler (JSON error handlers)
                                                              -> settings/transport -> application -> domain port
                                                              -> infrastructure (pgx, public.user_settings)
Deep link: io.github.example.leantracker://auth-callback -> supabase_flutter (PKCE exchange) -> auth event
           go_router also sees the link: route /auth-callback redirects to / (guard decides)
Local: GoTrue --SMTP--> Mailpit (UI http://127.0.0.1:8025); API JWKS = http://auth-gateway/auth/v1/.well-known/jwks.json
```

### Key Changes

**Contract (`apps/api/openapi.yaml`, then `make sync-contract` and `make gen`)**
```yaml
  /v1/settings:
    get:
      operationId: getSettings
      tags: [settings]
      responses:
        '200': { description: Goals of the caller, content: { application/json: { schema: { $ref: '#/components/schemas/Settings' } } } }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '404': { description: No goals saved yet (SETTINGS_NOT_FOUND), content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } } }
        '500': { $ref: '#/components/responses/InternalError' }
    put:
      operationId: putSettings
      tags: [settings]
      requestBody: { required: true, content: { application/json: { schema: { $ref: '#/components/schemas/Settings' } } } }
      responses:
        '200': { description: Stored goals, content: { application/json: { schema: { $ref: '#/components/schemas/Settings' } } } }
        '400': { description: Invalid goals or body (VALIDATION_ERROR), content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } } }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '500': { $ref: '#/components/responses/InternalError' }
# components.responses
    InternalError:
      description: Unexpected server error (INTERNAL_ERROR)
      content: { application/json: { schema: { $ref: '#/components/schemas/Error' } } }
# components.schemas
    Settings:
      type: object
      required: [goal_kcal, goal_protein_g, goal_fat_g, goal_carbs_g]
      properties:
        goal_kcal:      { type: integer, minimum: 500, maximum: 10000 }
        goal_protein_g: { type: integer, minimum: 0, maximum: 1000 }
        goal_fat_g:     { type: integer, minimum: 0, maximum: 1000 }
        goal_carbs_g:   { type: integer, minimum: 0, maximum: 1000 }
    ErrorCode:
      type: string
      enum: [UNAUTHORIZED, VALIDATION_ERROR, SETTINGS_NOT_FOUND, INTERNAL_ERROR]
```
- There is one `Settings` schema for the body and the response, with no `updated_at`. M6 adds it when sync needs it.
- The strict server does not enforce `minimum`/`maximum`. The domain does.
- The tag `settings` makes the Dart client `restClient.settings` (`SettingsClient`).

**Data model**
- No migration. `0001_user_settings.sql` already matches FR-002: check constraints, RLS on, no grants to `anon` or `authenticated`.
- Upsert: `insert ... on conflict (user_id) do update`, with `updated_at` taken from the injected clock.

**Limits (AD6)**
- `apps/api/internal/kernel/limits/limits.go`: `GoalKcalMin = 500`, `GoalKcalMax = 10000`, `GoalMacroMin = 0`, `GoalMacroMax = 1000` (BR-003).
- `apps/mobile/lib/kernel/limits/limits.dart`: `abstract final class Limits` with the same four values plus `passwordMinLength = 8` (FR-001, D-41). The password limit is app-side only, because it is a Supabase Auth setting, not part of the API contract.
- Contract tests:
  - Go: `kernel/limits/limits_contract_test.go` reads `apps/api/openapi.yaml` with `kin-openapi` (indirect becomes direct; no new module).
  - Dart: `test/kernel/limits_contract_test.dart` reads `apps/mobile/openapi.yaml` with dev `yaml`.

**API (`apps/api/internal/`)**
- `kernel/clock/clock.go`: `type Clock interface{ Now() time.Time }` and `type System struct{}`. ARCHITECTURE puts `Clock` in `kernel`.
- `settings/` module:
  - `internal/domain/goals.go`:
    ```go
    type Goals struct{ KCal, ProteinG, FatG, CarbsG int }
    type Field string // "goal_kcal", "goal_protein_g", "goal_fat_g", "goal_carbs_g"
    type OutOfRangeError struct{ Field Field; Min, Max int } // Error(); errors.As target
    var ErrNotFound = errors.New("settings: not found")
    func NewGoals(kcal, protein, fat, carbs int) (Goals, error) // first failing field as *OutOfRangeError
    type Repository interface {
        Get(ctx context.Context, userID string) (Goals, error) // ErrNotFound when no row
        Upsert(ctx context.Context, userID string, g Goals, at time.Time) error
    }
    ```
  - `internal/application/get_goals.go`: `GetGoals{repo}.Execute(ctx, userID) (domain.Goals, error)`.
  - `internal/application/save_goals.go`: `SaveGoals{repo, clock}.Execute(ctx, userID, kcal, protein, fat, carbs int) (domain.Goals, error)`. It calls `NewGoals` first, then `Upsert(..., clock.Now().UTC())`.
  - `internal/infrastructure/repository.go`:
    - `type Querier interface{ QueryRow(...) pgx.Row; Exec(...) (pgconn.CommandTag, error) }`, satisfied by `*pgxpool.Pool`.
    - `Get`: `select goal_kcal, goal_protein_g, goal_fat_g, goal_carbs_g from public.user_settings where user_id = $1`. `pgx.ErrNoRows` becomes `ErrNotFound`.
    - `Upsert`: `insert into public.user_settings (user_id, goal_kcal, goal_protein_g, goal_fat_g, goal_carbs_g, updated_at) values ($1,$2,$3,$4,$5,$6) on conflict (user_id) do update set goal_kcal = excluded.goal_kcal, goal_protein_g = excluded.goal_protein_g, goal_fat_g = excluded.goal_fat_g, goal_carbs_g = excluded.goal_carbs_g, updated_at = excluded.updated_at`.
  - `internal/transport/handler.go`: `Handler{get, save}` with `GetSettings` and `PutSettings` that match the generated strict signatures.
    - The user id comes only from `requestuser.UserID(ctx)`. If it is missing, the handler returns 401 `UNAUTHORIZED`. That is a defensive check; the middleware already gates.
    - `ErrNotFound` maps to 404 `SETTINGS_NOT_FOUND` "Goals are not set yet.".
    - `*OutOfRangeError` maps to 400 `VALIDATION_ERROR` "goal_kcal must be from 500 to 10000.". The message is built from the field and range; the app never shows it (AD5: the app maps codes).
    - Any other error maps to 500 `INTERNAL_ERROR` "Unexpected error.". It is logged with `slog` without the request body.
  - `settings.go` (facade, the only public file): `func New(db infrastructure.Querier, clock clock.Clock) *transport.Handler`. The facade builds its own adapter, because Go `internal/` hides `settings/internal/infrastructure` from `cmd/api`. `cmd/api` stays the composition root: it creates the pool and clock and passes them in. This is recorded as AD11.
- `platform/httpapi/router.go`:
  - The signature becomes `NewHandler(v jwtauth.TokenVerifier, api openapi.StrictServerInterface) http.Handler`.
  - It uses `openapi.NewStrictHandlerWithOptions(api, nil, openapi.StrictHTTPServerOptions{RequestErrorHandlerFunc: badRequest, ResponseErrorHandlerFunc: internalError})`.
  - `badRequest` writes 400 JSON `{code: VALIDATION_ERROR, message: "Request body is not valid."}`. `internalError` writes 500 JSON `{code: INTERNAL_ERROR, message: "Unexpected error."}`. Neither echoes input.
- `cmd/api/server.go`: `type server struct{ *httpapi.HealthServer; *transport-type via settings.New }`, an embedded composite. Method names do not collide.
- `cmd/api/main.go`: `httpapi.NewHandler(verifier, server{httpapi.NewHealthServer(pool), settings.New(pool, clock.System{})})`.

**Local auth stack (compose + Makefile)**
- `compose.yaml`, all new services under profile `auth`:
  - `auth`:
    - Image `supabase/auth:<pinned tag>`, the renamed GoTrue image. Pin the tag at implementation and record it.
    - `depends_on: db healthy`.
    - Database: `GOTRUE_DB_DRIVER=postgres`, `GOTRUE_DB_DATABASE_URL=postgres://supabase_auth_admin:postgres@db:5432/postgres?search_path=auth`. The password is "local only, not a secret".
    - Server and links: `API_EXTERNAL_URL=http://127.0.0.1:54321/auth/v1`, `GOTRUE_SITE_URL=io.github.example.leantracker://auth-callback`, `GOTRUE_URI_ALLOW_LIST=io.github.example.leantracker://auth-callback`.
    - Auth rules: `GOTRUE_EXTERNAL_EMAIL_ENABLED=true`, `GOTRUE_MAILER_AUTOCONFIRM=false`, `GOTRUE_PASSWORD_MIN_LENGTH=8`, `GOTRUE_JWT_AUD=authenticated`, `GOTRUE_JWT_DEFAULT_GROUP_NAME=authenticated`.
    - Mail: SMTP host `mailpit`, port 1025, admin email `noreply@localhost`.
    - Signing: the ES256 signing key from `.cache/auth/jwt-keys.json`. The variable name (`GOTRUE_JWT_KEYS`) and format are checked against the pinned tag.
    - Port not published.
  - `auth-gateway`: `nginx:<pinned>-alpine`. It mounts `./local/auth-gateway.conf` (`location /auth/v1/ { proxy_pass http://auth:9999/; }`, any other path returns 404) and publishes `54321:80`. `supabase_flutter` always calls `<SUPABASE_URL>/auth/v1/...`, and the hosted JWKS shape is `https://<ref>.supabase.co/auth/v1/.well-known/jwks.json`, so local and hosted paths match.
  - `mailpit`: `axllent/mailpit:<pinned>`. UI `8025:8025`, SMTP 1025 internal only.
  - `api` (profile `app`): `SUPABASE_JWKS_URL` defaults to `http://auth-gateway/auth/v1/.well-known/jwks.json`. With profile `app` alone, the old unreachable fallback behavior stays documented.
- `Makefile`:
  - `auth-keys`: `go run ./cmd/devjwk -out /work/.cache/auth/jwt-keys.json` in `GO_IMAGE`. It is skipped when the file exists. `apps/api/cmd/devjwk/main.go` is a stdlib-only program (`crypto/ecdsa`, `encoding/json`) that writes one ES256 private JWK with a `kid`. It is a dev tool, so the key never enters git and the M8 secret scan finds nothing.
  - `up`: `auth-keys`, then `docker compose --profile auth up -d --wait db auth auth-gateway mailpit`.
  - `db-reset`:
    1. `docker compose --profile auth --profile app down -v`.
    2. `docker compose up -d --wait db`.
    3. Apply the stub and migrations as today.
    4. `$(MAKE) up`. Auth starts after our migrations. `auth.users` already exists in the image, so the FK in 0001 resolves.
  - `down`: `--profile app --profile auth`.
  - `lint-dart` format paths: `lib/main.dart lib/app lib/kernel lib/ui lib/auth lib/settings test`.
  - `gen-dart`: adds `flutter gen-l10n`.
- `.env.example` (root) and `apps/api/.env.example`: the local JWKS URL is `http://127.0.0.1:54321/auth/v1/.well-known/jwks.json` (host) or `http://auth-gateway/...` (compose).

**Mobile (`apps/mobile/`)**
- **Config:**
  - `env/example.json` (tracked): keys `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`. Run with `flutter run --dart-define-from-file=env/local.json` (git-ignored). The Android emulator reaches the host as `10.0.2.2`.
  - `lib/app/config.dart`: `abstract final class AppConfig` with `String.fromEnvironment` for the three keys and `authCallbackUrl = 'io.github.example.leantracker://auth-callback'`. Its `missingKeys` getter names the missing keys and never prints values.
- **Bootstrap:**
  - `lib/main.dart`: `void main() => bootstrap();`.
  - `lib/app/bootstrap.dart`: checks `AppConfig`. If keys are missing, it runs a fixed `ConfigErrorApp`, a developer-only English screen. Otherwise it calls `Supabase.initialize(url, anonKey, authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce, localStorage: SecureSessionStorage()))`, then `runApp(ProviderScope(child: LeanTrackerApp()))`.
- **`lib/kernel/limits/limits.dart`:** see Limits.
- **`lib/auth/`** (public file `auth.dart`):
  - `domain/email.dart`: `Email.parse(String) -> Email`, throws or returns a failure. Trimmed, regex `^[^@\s]+@[^@\s]+\.[^@\s]+$`.
  - `domain/password.dart`: `Password.parse`, with length ≥ `Limits.passwordMinLength`.
  - `domain/auth_failure.dart`: `sealed class AuthFailure` with `InvalidEmail`, `PasswordTooShort`, `EmailAlreadyRegistered`, `WrongCredentials`, `EmailNotConfirmed`, `NoConnection`, `SocialSignInFailed`, `UnknownAuthFailure`.
  - `domain/auth_status.dart`: `enum AuthStatus { loading, signedOut, awaitingConfirmation, recovering, signedIn }`.
  - `application/auth_gateway.dart`, the port:
    - Members: `Stream<AuthStatus> status`, `AuthStatus get current`, `Future<String?> accessToken()`, `signUp(Email, Password)`, `signIn(Email, Password)`, `signInWithProvider(SocialProvider)` (`enum SocialProvider { google, apple }`), `requestPasswordReset(Email)`, `setNewPassword(Password)`, `signOut()`.
    - Failures come back as `AuthFailure`, in a sealed result `AuthResult = AuthOk | AuthError(AuthFailure)`.
  - Use cases in `application/`: `sign_up.dart`, `sign_in.dart`, `sign_in_with_provider.dart`, `request_password_reset.dart`, `set_new_password.dart`, `sign_out.dart`. Each parses raw strings with the domain types first, and never calls the gateway with invalid input.
  - `infrastructure/supabase_auth_gateway.dart`:
    - Wraps `SupabaseClient.auth`.
    - Sign-up uses `emailRedirectTo: AppConfig.authCallbackUrl`. OAuth and reset use `redirectTo` with the same URL.
    - Status: `onAuthStateChange` maps `passwordRecovery` to `recovering`, `signedIn`/`tokenRefreshed`/`initialSession` with a session to `signedIn`, and `signedOut` to `signedOut`. After `signUp` without a session the status is `awaitingConfirmation`.
    - Errors are mapped by `AuthException.code`, never by message text:
      - `invalid_credentials` → `WrongCredentials`
      - `email_not_confirmed` → `EmailNotConfirmed`
      - `weak_password` → `PasswordTooShort`
      - `user_already_exists` / `email_exists` → `EmailAlreadyRegistered`
      - `SocketException` / `AuthRetryableFetchException` → `NoConnection`
      - an OAuth launch that fails or is cancelled → `SocialSignInFailed`
      - anything else → `UnknownAuthFailure`
    - **Sign-up with an existing email returns a user with empty `identities` and no error when confirmation is on.** That case maps to `EmailAlreadyRegistered`.
    - The mapping lives in a pure function `mapAuthError(code, statusCode)` in `infrastructure/auth_error_mapping.dart`, so it can be unit-tested.
  - `infrastructure/secure_session_storage.dart`: `SecureSessionStorage extends LocalStorage`, backed by `flutter_secure_storage` (PRD §14).
  - `presentation/`, board **Logowanie**:
    - `login_screen.dart` + `login_controller.dart` (`Notifier`). Fields: email and password. Buttons: Zaloguj się (primary), Załóż konto, the "Nie pamiętasz hasła?" link, "lub", Kontynuuj z Google, Kontynuuj z Apple. Apple shows on both platforms.
    - `check_email_screen.dart`, `forgot_password_screen.dart`, `new_password_screen.dart` with controllers.
    - `auth_failure_text.dart`: `String authFailureText(AppLocalizations, AuthFailure)` with an exhaustive switch. It is the only place failures become text.
- **`lib/settings/`** (public file `settings.dart`):
  - `domain/goals.dart`: `Goals(kcal, protein, fat, carbs)`, `enum GoalField { kcal, protein, fat, carbs }` with `min`/`max` from `Limits`, and `Map<GoalField, GoalError> validateGoals(Map<GoalField, String> raw)` (`enum GoalError { missing, notInteger, outOfRange }`). It returns `Goals` or the error map through a sealed `GoalsInput = ValidGoals | InvalidGoals`.
  - `application/goals_repository.dart`: the port, `Future<GoalsLoad> load()` and `Future<GoalsSave> save(Goals)`.
    - `sealed GoalsLoad = GoalsFound(Goals) | GoalsMissing | GoalsUnavailable`.
    - `sealed GoalsSave = GoalsSaved(Goals) | GoalsRejected | GoalsOffline`.
  - Use cases: `load_goals.dart` and `save_goals.dart`. `SaveGoals(raw)` validates first and returns the field errors without calling the port.
  - `infrastructure/api_goals_repository.dart`:
    - Uses `restClient.settings` (generated).
    - On load, a 404 with `SETTINGS_NOT_FOUND` becomes `GoalsMissing`. A connection error, timeout or 5xx becomes `GoalsUnavailable`.
    - On save, 400 becomes `GoalsRejected` and a connection error becomes `GoalsOffline`.
    - Codes are read from the `Error` body, never from text. Bodies are never logged.
  - `presentation/`:
    - `goals_form.dart`: one form widget used by onboarding and by editing (board **Cele**). It has four fields with unit suffixes, and Save is enabled only when all four are valid (UF-001 step 3). Field errors come from ARB: "Enter a value from 500 to 10000." and "Enter a value from 0 to 1000.".
    - `goals_screen.dart`: onboarding. It includes the mascot line and the button "Zapisz i przejdź do dziennika". The mascot graphic is drawn only if the board's graphic is plain shapes; no new package and no image asset is added for it.
    - `edit_goals_screen.dart`: from Settings.
    - `settings_screen.dart` (board **Ustawienia**): section Cele (energy and macros summary, tap opens edit), section "Język i motyw" with "Zgodnie z ustawieniami systemu.", and Wyloguj się. No Reminders and no Delete account (M7).
- **`lib/app/`:**
  - `providers.dart` (AD9): `authGatewayProvider`, `authStatusProvider` (`StreamProvider`), `dioProvider`, `restClientProvider`, `goalsRepositoryProvider`, `goalsProvider` (`AsyncNotifier` over `LoadGoals`, invalidated after save and on sign-out).
  - `http_client.dart`: `Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl, connectTimeout: 10s, receiveTimeout: 10s))` plus an interceptor that sets `Authorization: Bearer` from `AuthGateway.accessToken()`. `supabase_flutter` refreshes the token.
  - `route_guard.dart`: pure Dart.
    ```dart
    enum GoalsStatus { unknown, missing, saved, unavailable }
    String? redirectFor({required AuthStatus auth, required GoalsStatus goals, required String location});
    ```
    - `loading` → `/start`.
    - `signedOut` → `/login`. The routes `/login`, `/forgot-password` and `/check-email` stay allowed.
    - `awaitingConfirmation` → `/check-email`.
    - `recovering` → `/new-password` only.
    - `signedIn` + `unknown` → `/start`.
    - `signedIn` + `unavailable` → `/start`, which shows "No connection. Try again." and a retry.
    - `signedIn` + `missing` → `/goals`.
    - `signedIn` + `saved` on `/start`, `/login`, `/goals` or `/check-email` → `/diary`.
    - Otherwise `null`.
  - `router.dart`:
    - Routes: `/start`, `/login`, `/check-email`, `/forgot-password`, `/new-password`, `/goals`, `/auth-callback`, and a `StatefulShellRoute` with `/diary` (placeholder) and `/settings` (+ `/settings/goals`).
    - `/auth-callback` redirects to `/start`. go_router also receives the custom-scheme link, and `supabase_flutter` handles the code exchange.
    - The guard is `redirectFor`. `refreshListenable` is driven by `authStatusProvider` and `goalsProvider`.
  - `shell_scaffold.dart`: Material 3 `NavigationBar` with two destinations, Dziennik and Ustawienia, laid out as the DESIGN bottom bar. Tydzień is added in M5.
  - `diary_placeholder_screen.dart`: title Dziennik plus one ARB line. M3 replaces it.
  - `app.dart`: `MaterialApp.router` with `theme`/`darkTheme` from `ui/`, `themeMode: ThemeMode.system`, delegates (`AppLocalizations.delegate`, `GlobalMaterialLocalizations/Widgets/Cupertino`), `supportedLocales: [en, pl]`, and a `localeResolutionCallback` that falls back to `en` (FR-017).
- **`lib/ui/`:**
  - `tokens.dart`: light and dark palettes and the meal accents (used from M3), radii and spacing. They are extracted once from `docs/DESIGN.html` with a scratchpad script. The boards are gzip+base64 nested bundles under `__bundler/manifest`; decode two levels and read the `__bundler/template`. Never Read the file whole.
  - `theme.dart`: `ThemeData lightTheme()` / `darkTheme()` with an explicit `ColorScheme` from tokens, `useMaterial3: true` and `fontFamily: 'Nunito'`. Text contrast is checked to be ≥ 4.5:1 for the chosen pairs.
  - `assets/fonts/`: Nunito static TTFs (Regular, SemiBold, Bold, ExtraBold, or the weights the boards use) from the official `googlefonts/nunito` release, plus `OFL.txt`, declared under `flutter: fonts:`.
- **l10n:**
  - `l10n.yaml`: `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `nullable-getter: false`.
  - ARB files: `lib/l10n/app_en.arb` and `app_pl.arb`.
  - Output is generated into `lib/l10n/` (Flutter 3.44 has no synthetic package) and **committed**, like the other generated code (D-64), via `make gen-dart`. If the pinned Flutter still offers `synthetic-package`, keep it off for that reason.
- **Platform:**
  - `android/app/src/main/AndroidManifest.xml`:
    - Add `<uses-permission android:name="android.permission.INTERNET"/>`. Release builds lack it today.
    - Add on `.MainActivity` an `intent-filter` with `VIEW`, `DEFAULT`, `BROWSABLE` and `<data android:scheme="io.github.example.leantracker" android:host="auth-callback"/>`.
    - `android/app/src/debug/AndroidManifest.xml`: `android:usesCleartextTraffic="true"` for the local `http://10.0.2.2` stack, debug only.
  - `ios/Runner/Info.plist`:
    - `CFBundleURLTypes` with scheme `io.github.example.leantracker`.
    - `NSAppTransportSecurity` → `NSAllowsLocalNetworking = true`, so the simulator reaches `http://127.0.0.1`. That flag allows local addresses only.
    - `CFBundleLocalizations` `[en, pl]`.
- **Dependencies:**
  - Runtime:
    - `supabase_flutter` (PRD §18).
    - `flutter_localizations` (SDK).
    - `intl` (gen-l10n; version as the SDK pins).
    - `flutter_secure_storage` (owner-approved 2026-11-27, PRD §14).
  - Dev: `yaml` (owner-approved 2026-11-27, AD6 test).
  - Go: `kin-openapi` goes from indirect to direct. No new module.
  - Platform: deep-link intent filter and URL type, `INTERNET`, ATS local networking. No camera or notification permissions.

**UI texts (new ARB keys; PRD §11 is updated with the ones §11 lacks)**

| Key | EN | PL | Source |
| --- | --- | --- | --- |
| appTitle | Lean Tracker | Lean Tracker | DESIGN |
| loginTagline | Log meals fast and calmly. | Zapisuj posiłki szybko i na spokojnie. | DESIGN |
| emailLabel | Email | E-mail | DESIGN |
| passwordLabel | Password (min. 8 characters) | Hasło (min. 8 znaków) | DESIGN |
| forgotPasswordLink | Forgot your password? | Nie pamiętasz hasła? | DESIGN |
| signInButton | Sign in | Zaloguj się | §11 / DESIGN |
| signUpButton | Sign up | Załóż konto | §11 / DESIGN |
| orDivider | or | lub | DESIGN |
| continueWithGoogle | Continue with Google | Kontynuuj z Google | DESIGN |
| continueWithApple | Continue with Apple | Kontynuuj z Apple | DESIGN |
| errorInvalidEmail | Enter a valid email address. | Podaj poprawny adres e-mail. | §11 |
| errorPasswordTooShort | Password must have at least 8 characters. | Hasło musi mieć co najmniej 8 znaków. | §11 |
| errorEmailTaken | This email is already registered. | Ten e-mail jest już zarejestrowany. | §11 |
| errorNoConnection | No connection. Try again. | Brak połączenia. Spróbuj ponownie. | §11 |
| errorSocialSignIn | Sign-in failed. Try again. | Logowanie nie powiodło się. Spróbuj ponownie. | §15 |
| errorWrongCredentials | Wrong email or password. | Nieprawidłowy e-mail lub hasło. | new §11 |
| errorEmailNotConfirmed | Confirm your email first. Check your inbox. | Najpierw potwierdź e-mail. Sprawdź skrzynkę. | new §11 |
| errorUnknown | Something went wrong. Try again. | Coś poszło nie tak. Spróbuj ponownie. | new §11 |
| checkEmailTitle | Check your email | Sprawdź skrzynkę | new §11 |
| checkEmailBody | Check your email to confirm your account. Open the link on this phone. | Sprawdź skrzynkę e-mail, aby potwierdzić konto. Otwórz link na tym telefonie. | new §11 |
| backToSignIn | Back to sign in | Wróć do logowania | new §11 |
| resetTitle | Reset password | Resetuj hasło | new §11 |
| resetBody | Enter your email. We will send a link to set a new password. | Podaj e-mail. Wyślemy link do ustawienia nowego hasła. | new §11 |
| resetSend | Send link | Wyślij link | new §11 |
| resetSent | Check your email to reset your password. | Sprawdź skrzynkę e-mail, aby zresetować hasło. | new §11 |
| newPasswordTitle | Set a new password | Ustaw nowe hasło | new §11 |
| newPasswordSave | Save password | Zapisz hasło | new §11 |
| goalsTitle | Your daily goals | Twoje dzienne cele | DESIGN |
| goalsSubtitle | Enter them manually. You can change them later in settings. | Wpisz je ręcznie. Zmienisz je później w ustawieniach. | DESIGN |
| goalsMascot | I'm Blueberry. Let's start with your goals. | Jestem Borówka. Zacznijmy od Twoich celów. | DESIGN |
| goalKcalLabel | Energy (500–10000) | Energia (500–10000) | DESIGN |
| goalProteinLabel | Protein (0–1000) | Białko (0–1000) | DESIGN |
| goalFatLabel | Fat (0–1000) | Tłuszcz (0–1000) | DESIGN |
| goalCarbsLabel | Carbohydrates (0–1000) | Węglowodany (0–1000) | DESIGN |
| unitKcal / unitGram | kcal / g | kcal / g | DESIGN |
| goalsSaveAndContinue | Save and go to diary | Zapisz i przejdź do dziennika | DESIGN |
| goalsSave | Save | Zapisz | new §11 |
| errorKcalRange | Enter a value from 500 to 10000. | Podaj wartość od 500 do 10000. | §12 FR-002 |
| errorMacroRange | Enter a value from 0 to 1000. | Podaj wartość od 0 do 1000. | §11 pattern |
| settingsTitle | Settings | Ustawienia | DESIGN |
| settingsGoals | Goals | Cele | DESIGN |
| settingsEnergy | Energy | Energia | DESIGN |
| settingsMacros | Protein / fat / carbs | Białko / tłuszcz / węgle | DESIGN |
| settingsLanguageTheme | Language and theme | Język i motyw | DESIGN |
| settingsFollowsSystem | Follows system settings. | Zgodnie z ustawieniami systemu. | DESIGN |
| signOut | Sign out | Wyloguj się | §11 / DESIGN |
| navDiary | Diary | Dziennik | DESIGN |
| navSettings | Settings | Ustawienia | DESIGN |
| diaryPlaceholder | Diary arrives in the next version. | Dziennik pojawi się w kolejnej wersji. | temporary, removed in M3 |
| retry | Try again | Spróbuj ponownie | new §11 |

### Fit with Project Docs
- **PRD:**
  - Implements FR-001, FR-002, FR-017, UF-001, UF-006 (partial: goals, language info, sign out), BP-006, BR-001, BR-002, BR-003 and NFR-004.
  - Bent rules:
    - FR-001 criterion 1 says "consent screen". No consent screen exists (analytics is §23), so it becomes the check-email screen.
    - FR-002 criterion 2 ("Diary shows the new goals") can hold only from M3. In M2 it is checked in Settings.
    - Email confirmation and password reset add screens and texts §11 lacks. They are added to §11.
- **ARCHITECTURE.md:**
  - Modules `auth` and `settings` live in both apps (AD2).
  - Supabase, `flutter_secure_storage`, Dio and `lib/gen` are only in mobile `infrastructure`/`app`. SQL is only in Go `infrastructure`.
  - `Clock` is in `kernel` (Go). Providers and the router are in `app/` (AD9).
  - `app/` reaches modules only through `auth.dart` and `settings.dart`.
  - The route guard consumes `AuthStatus` (from auth) and its own `GoalsStatus`, so settings does not import auth (AD3).
  - Errors are typed inside and mapped once: in transport to codes, and in presentation to text (AD5).
  - Deviation, recorded as **AD11**: a Go module facade builds its own adapters from a pool and clock that `cmd/api` passes in, because Go `internal/` hides the adapter package from `cmd/api`.
- **CODE_QUALITY.md:**
  - KISS: no cache, no native SDKs, one goals form for two screens. YAGNI: no `updated_at` on the wire, no Reminders or Delete stubs, no Tydzień tab.
  - Single sources: limits come from the contract, are mirrored and are tested. Texts are in ARB, tokens in `ui/`.
  - Errors are matched by code, never text. Emails, passwords and tokens are never logged.
  - Fakes over mocks.
- **Docs to update:**
  - PRD §11:
    - UF-001 gets step 2a (check-email), a Forgot password sub-flow and the new error texts.
    - UF-006 gets a note that the M2 Settings screen has Goals, Language and theme, and Sign out.
  - PRD §12: FR-001 criterion 1 wording and the FR-002 criterion 2 note.
  - PRD §20:
    - **D-71**: local Supabase Auth (GoTrue) with an nginx `/auth/v1` gateway and Mailpit in compose, started by `make up`. ES256 dev key generated by `make auth-keys`. Amends D-66 (local stack is no longer Postgres only).
    - **D-72**: email confirmation on; password reset in M2; deep link `io.github.example.leantracker://auth-callback`; browser OAuth for Google and Apple; PKCE.
    - **D-73**: goals are stored only through the API in M2 (no local cache until M3); a single `Settings` schema without `updated_at`; generic error codes `VALIDATION_ERROR`, `SETTINGS_NOT_FOUND`, `INTERNAL_ERROR`.
    - **D-74**: `flutter_secure_storage` for the session (PRD §14), dev `yaml` for the AD6 test, and `API_BASE_URL` as a non-secret dart-define.
  - Bump the PRD version line.
  - ARCHITECTURE:
    - Layout: `apps/mobile/lib/l10n/` (fix the `ui/` mention), `apps/mobile/env/`, `local/auth-gateway.conf`, `apps/api/cmd/devjwk/`, `internal/kernel/clock`, `internal/kernel/limits`, `lib/kernel/limits`.
    - Add **AD11**.
  - CODE_QUALITY single-sources row "UI text": unchanged (`lib/l10n/*.arb`).
  - README: `make up` now starts auth and Mailpit, plus `env/local.json`, emulator host `10.0.2.2` and the Mailpit URL. `apps/mobile/README.md` gets the run command.

### Alternative Approaches Considered
- **Local auth:**
  - Hosted Auth + a seed helper: manual `auth.users` rows, no offline email flow.
  - Hosted DB: bends D-61.
  - Supabase CLI stack: needs a host install, against D-66.
  - Chosen: GoTrue in compose (owner).
- **Gateway:**
  - The Kong image as the CLI uses it: heavy config.
  - The `gotrue` Dart client pointed at the root: loses `supabase_flutter` session and deep-link handling.
  - Chosen: nginx with one `location`.
- **Social login:** native `google_sign_in` + `sign_in_with_apple` means two new packages and more platform config, and Apple on Android is still web. Chosen: browser OAuth (owner).
- **Goals store:** a local cache now is throwaway before Drift, and local-only loses goals on a new device. Chosen: API-only (owner).
- **Error codes:** route-specific `GOALS_OUT_OF_RANGE`/`INVALID_REQUEST` vs generic. Chosen: generic (owner).
- **Schema:** separate `GoalsInput` + `Settings` with `updated_at` vs one `Settings`. Chosen: one (owner).
- **Auth stack start:** separate `make up-auth` vs part of `make up`. Chosen: `make up` (owner).
- **Strict server composition:** per-tag codegen (several configs) vs one embedded composite struct in `cmd/api`. Chosen: composite.
- **Dev key generation:** an openssl image (new image, PEM to JWK conversion) vs a stdlib Go program in `GO_IMAGE`. Chosen: Go.
- **Session storage:** the `supabase_flutter` default SharedPreferences breaks PRD §14. Chosen: `flutter_secure_storage` (owner-approved).
- **Already-registered detection:** a sign-up pre-check endpoint (leaks enrolment) vs Supabase's empty-`identities` signal. Chosen: the signal.

## Implementation Steps

**Contract and limits**
1. [x] In `apps/api/openapi.yaml`, add `/v1/settings` `get` and `put`, `components.responses.InternalError`, schema `Settings` and the `ErrorCode` values `VALIDATION_ERROR`, `SETTINGS_NOT_FOUND`, `INTERNAL_ERROR`, exactly as in Key Changes. Bump `info.version` to `0.2.0`.
2. [x] Run `make sync-contract` and `make gen`. Check that `openapi.gen.go` has `GetSettings200JSONResponse`, `GetSettings404JSONResponse`, `PutSettings400JSONResponse` and `ErrorCodeVALIDATIONERROR` (exact names as generated), and that `lib/gen` has `SettingsClient` and `Settings`. Do not edit generated files.
3. [x] Create `apps/api/internal/kernel/limits/limits.go` (four constants, BR-003 comment) and `apps/api/internal/kernel/clock/clock.go` (`Clock`, `System`).
4. [x] Create `apps/api/internal/kernel/limits/limits_contract_test.go`. Load `../../../openapi.yaml` with `openapi3.NewLoader().LoadFromFile`, read `Settings` property `Min`/`Max`, and assert equality with the constants. Run `go mod tidy` through `GO_RUN` so `kin-openapi` becomes direct.

**Go settings module**
5. [x] Create `apps/api/internal/settings/internal/domain/goals.go` (`Goals`, `Field`, `OutOfRangeError`, `ErrNotFound`, `NewGoals`, `Repository`) using `kernel/limits`.
6. [x] Create `apps/api/internal/settings/internal/domain/goals_test.go`, table-driven: kcal 499/500/10000/10001; each macro -1/0/1000/1001; all valid. Each failure names its `Field` via `errors.As` (BR-003).
7. [x] Create `apps/api/internal/settings/internal/application/get_goals.go` and `save_goals.go`, with tests in `application/goals_test.go` on an in-memory fake repository and a fixed clock: save stamps `updated_at` from the clock in UTC; invalid goals never reach the repository; get for an unknown user returns `ErrNotFound`; user A's save is not visible to user B.
8. [x] Create `apps/api/internal/settings/internal/infrastructure/repository.go` (`Querier`, `NewRepository`, `Get`, `Upsert`, SQL as in Key Changes, explicit columns, bound parameters).
9. [x] Create `apps/api/internal/settings/internal/infrastructure/repository_test.go`. It is skipped unless `TEST_DATABASE_URL` is set. It inserts two ids into `auth.users`, then checks: B cannot read A; a second upsert for A updates one row; an upsert for B leaves A's values unchanged; get for a new id returns `ErrNotFound` (BR-001).
10. [x] Create `apps/api/internal/settings/internal/transport/handler.go` (`GetSettings`, `PutSettings`, mapping as in Key Changes) and `handler_test.go`. The test uses `httptest`, the generated strict handler and the fake repository, with the user id set via `requestuser.WithUserID`. Cases: GET with no row returns 404 `SETTINGS_NOT_FOUND`; PUT kcal 499 returns 400 `VALIDATION_ERROR`; PUT valid returns 200 echoing the goals; GET after PUT returns the same values; no user id returns 401; a repository error returns 500 `INTERNAL_ERROR` without leaking the error text.
11. [x] Create `apps/api/internal/settings/settings.go`: `func New(db infrastructure.Querier, clk clock.Clock) *transport.Handler` (or an exported alias type), with a comment citing AD11.
12. [x] Modify `apps/api/internal/platform/httpapi/router.go`: `NewHandler(v, api openapi.StrictServerInterface)` with `NewStrictHandlerWithOptions` and the JSON `badRequest`/`internalError` handlers. Update `router_test.go` and `health_test.go` to the new signature. Add cases: GET and PUT `/v1/settings` without a token return 401; a malformed JSON PUT with a token returns 400 JSON `VALIDATION_ERROR`.
13. [x] Create `apps/api/cmd/api/server.go` (the composite `server` struct) and modify `cmd/api/main.go` to wire `settings.New(pool, clock.System{})`.

**Local auth stack**
14. [x] Create `apps/api/cmd/devjwk/main.go`: stdlib only, writes an ES256 private JWK set (`{"keys":[{kty, crv, x, y, d, kid, alg:"ES256", use:"sig", key_ops:["sign","verify"]}]}`) to `-out`, and refuses to overwrite. Pin `supabase/auth`, `nginx` and `axllent/mailpit` tags. Check the pinned GoTrue tag's variable for asymmetric keys (expected `GOTRUE_JWT_KEYS`) and its JWKS path (`/.well-known/jwks.json`). Record tags and variable names in the Implementation Log.
15. [x] Create `local/auth-gateway.conf` (`location /auth/v1/ { proxy_pass http://auth:9999/; proxy_set_header Host $host; proxy_set_header X-Forwarded-Proto $scheme; }`, `location / { return 404; }`).
16. [x] Modify `compose.yaml`: add `auth`, `auth-gateway` and `mailpit` under profile `auth` as in Key Changes, with the key file mounted read-only from `./.cache/auth/jwt-keys.json`. Change the `api` `SUPABASE_JWKS_URL` default to `http://auth-gateway/auth/v1/.well-known/jwks.json`. Label every local password "local only, not a secret".
17. [x] Modify the root `Makefile`:
    - add `auth-keys`;
    - `up` runs `auth-keys` plus the auth profile;
    - `db-reset` runs down `-v` (both profiles), db only, stub and migrations, then `$(MAKE) up`;
    - `down` covers both profiles;
    - `lint-dart` format paths: `lib/main.dart lib/app lib/kernel lib/ui lib/auth lib/settings test`;
    - `gen-dart` adds `flutter gen-l10n`;
    - update `.PHONY`.
18. [x] Update the root `.env.example` and `apps/api/.env.example` comments with the local JWKS URLs, host and compose.

**Mobile foundation**
19. [x] `apps/mobile/pubspec.yaml`:
    - add `supabase_flutter`, `flutter_secure_storage`, `flutter_localizations` (sdk) and `intl`, plus dev `yaml`;
    - add `flutter: generate: true` and a `fonts:` entry for Nunito;
    - replace the `description` placeholder with "Lean Tracker mobile app.".
    Run `flutter pub get` through `FLUTTER_RUN` and commit `pubspec.lock` changes with the step.
20. [x] Add `apps/mobile/assets/fonts/Nunito-*.ttf` (the weights the boards use, from the official `googlefonts/nunito` release) and `apps/mobile/assets/fonts/OFL.txt`.
21. [x] Create `apps/mobile/l10n.yaml`, `lib/l10n/app_en.arb` and `lib/l10n/app_pl.arb` with every key in the UI texts table (with `@` descriptions in EN). Run `make gen-dart` and commit the generated `lib/l10n/app_localizations*.dart`.
22. [x] Create `apps/mobile/lib/kernel/limits/limits.dart` and `apps/mobile/test/kernel/limits_contract_test.dart`. The test reads `openapi.yaml` with `package:yaml`, compares the `Settings` `minimum`/`maximum` values, and asserts `passwordMinLength == 8`.
23. [x] Extract tokens from `docs/DESIGN.html` with a scratchpad script (boards Logowanie, Cele, Ustawienia, Dziennik light and dark). Create `lib/ui/tokens.dart` and `lib/ui/theme.dart` (`lightTheme()`, `darkTheme()`, Nunito) and record the token values' source in the Implementation Log. Add `test/ui/theme_test.dart`: both themes use Material 3 and Nunito, and the primary text and surface pairs reach a contrast ratio ≥ 4.5 (computed in the test).
24. [x] Create `apps/mobile/env/example.json` and `lib/app/config.dart` (`AppConfig`, `missingKeys`), with `test/app/config_test.dart` for `missingKeys` naming keys only.

**Mobile settings module**
25. [x] Create `lib/settings/domain/goals.dart` (`Goals`, `GoalField`, `GoalError`, `GoalsInput`, `validateGoals`) and `test/settings/domain/goals_test.dart`: boundaries 499/500/10000/10001 and -1/0/1000/1001, empty, non-integer ("12.5", "abc"), and all valid (BR-003).
26. [x] Create `lib/settings/application/goals_repository.dart` (port and sealed results), `load_goals.dart` and `save_goals.dart`, and `test/settings/application/goals_use_cases_test.dart` with `FakeGoalsRepository`. Cases: invalid input never calls `save`; `GoalsMissing` passes through; `GoalsSaved` returns the goals.
27. [x] Create `lib/settings/infrastructure/api_goals_repository.dart` over `restClient.settings`. Put the mapping from status code and `Error.code` to sealed results in a pure function `mapGoalsError(int? status, ErrorCode? code, DioExceptionType type)`, and test it in `test/settings/infrastructure/goals_error_mapping_test.dart`: 404/SETTINGS_NOT_FOUND is missing; 400 is rejected; connection error and timeout are offline or unavailable; 500 is unavailable.
28. [x] Create `lib/settings/settings.dart`, exporting only what `app/` needs: `Goals`, the port, the use cases, `ApiGoalsRepository` and the screens.

**Mobile auth module**
29. [x] Create `lib/auth/domain/email.dart`, `password.dart`, `auth_failure.dart`, `auth_status.dart`, and `test/auth/domain/email_test.dart` and `password_test.dart` (7 characters rejected, 8 accepted, empty rejected; trimmed email; invalid formats).
30. [x] Create `lib/auth/application/auth_gateway.dart` (port, `SocialProvider`, `AuthResult`) and the six use cases. Create `test/auth/application/auth_use_cases_test.dart` with `FakeAuthGateway`. Cases: sign-up with a 7-character password never calls the gateway and returns `PasswordTooShort` (FR-001 criterion 2); invalid email returns `InvalidEmail`; `EmailAlreadyRegistered` passes through; sign-out calls the gateway; reset with invalid email never calls the gateway.
31. [x] Create `lib/auth/infrastructure/auth_error_mapping.dart` (pure `mapAuthError` plus `isExistingUserSignUp(identitiesLength)`) and `test/auth/infrastructure/auth_error_mapping_test.dart`, covering every code in Key Changes, an unknown code and empty identities.
32. [x] Create `lib/auth/infrastructure/supabase_auth_gateway.dart` (with redirect URLs, status stream mapping and the mapping functions from step 31) and `secure_session_storage.dart` (`LocalStorage` over `FlutterSecureStorage`). Neither logs emails, passwords or tokens.
33. [x] Create `lib/auth/auth.dart`, exporting the domain types, the port, the use cases, the gateway, the storage and the screens.

**App wiring, screens, routing**
34. [x] Create `lib/app/route_guard.dart` (`GoalsStatus`, `redirectFor`) and `test/app/route_guard_test.dart` with a table of every rule in Key Changes, including no loop (`redirectFor` on its own target returns `null`).
35. [x] Create `lib/app/bootstrap.dart` and `lib/app/http_client.dart`, and modify `lib/main.dart`. Create `lib/app/providers.dart` (AD9) with `goalsProvider` mapping `GoalsLoad` to `GoalsStatus`, and invalidation after save and on sign-out.
36. [x] Create the auth screens (`login_screen.dart`, `check_email_screen.dart`, `forgot_password_screen.dart`, `new_password_screen.dart`), their controllers, and `auth_failure_text.dart` (exhaustive switch to ARB). Follow board Logowanie. `Semantics` labels go on every field and button. Layout is a scrollable column, so 360 dp and 200% font do not overflow.
37. [x] Create the settings screens (`goals_form.dart`, `goals_screen.dart`, `edit_goals_screen.dart`, `settings_screen.dart`) following boards Cele and Ustawienia, plus `lib/app/shell_scaffold.dart` (Dziennik and Ustawienia) and `lib/app/diary_placeholder_screen.dart`.
38. [x] Rewrite `lib/app/router.dart` (routes and guard as in Key Changes, `/auth-callback`, `StatefulShellRoute`) and `lib/app/app.dart` (themes, `ThemeMode.system`, delegates, `supportedLocales`, `en` fallback).
39. [x] Widget tests with fake gateway and repository via provider overrides:
    - `test/app/app_test.dart`: signed-out shows the login screen; system locale `pl` shows "Zaloguj się" (FR-017); `platformBrightness: dark` uses `darkTheme` (FR-017).
    - `test/auth/presentation/login_screen_test.dart`: a 7-character password plus Sign up shows "Password must have at least 8 characters."; `EmailAlreadyRegistered` shows "This email is already registered."; `NoConnection` shows "No connection. Try again.".
    - `test/settings/presentation/goals_form_test.dart`: kcal 499 shows "Enter a value from 500 to 10000." and Save is disabled (FR-002 criterion 1); four valid values enable Save.
40. [x] Platform files:
    - main `AndroidManifest.xml`: `INTERNET` and the deep-link `intent-filter`;
    - debug manifest: `usesCleartextTraffic`;
    - `Info.plist`: `CFBundleURLTypes`, `NSAllowsLocalNetworking`, `CFBundleLocalizations`.

**Docs and final checks**
41. [x] `docs/PRD.md`: §11 UF-001 and UF-006 additions (new texts from the table marked "new §11"), §12 FR-001 criterion 1 and the FR-002 note, §20 D-71 to D-74, and the version line.
42. [x] `docs/ARCHITECTURE.md`: Layout updates and AD11. `README.md` and `apps/mobile/README.md`: local run (`make up`, `make auth-keys`, Mailpit `http://127.0.0.1:8025`, `env/local.json`, `10.0.2.2`, Google and Apple only against the hosted project).
43. [x] Run `make check-contract`, `make lint` and `make test`, and fix findings. In the Implementation Log, mark FR-001 criteria 1–2 and FR-002 criterion 1 as covered by unit and widget tests, and FR-001 criterion 3 and FR-002 criterion 2 as manual or `lean-e2e`.

## Checkpoints (Todo List)
- [x] CP1 — Contract, limits, Go settings module: steps 1–13; `make check-contract` exits 0, `make lint-go` clean, `make test-go` green, including `kernel/limits/limits_contract_test.go`, `settings/internal/{domain,application,transport}` tests and `platform/httpapi/router_test.go`. — make lint-go, make test-go and make check-contract not run (not selected); sync-contract and gen ran in step 2
- [x] CP2 — Local auth stack: steps 14–18. Evidence: `docker compose --profile auth --profile app config -q` passes; `make -n` dry run of the Makefile targets OK. — make lint-go and make test-go not run (not selected); make db-reset not run (not selected)
- [x] CP3 — Mobile foundation: steps 19–24; `make lint-dart` clean; `test/kernel/limits_contract_test.dart`, `test/ui/theme_test.dart` and `test/app/config_test.dart` green. — make lint-dart and make test-dart not run (not selected); dart format applied to lib/main.dart, lib/app, lib/kernel, lib/ui and test
- [x] CP4 — Settings and auth logic: steps 25–33; `make test-dart` green with `test/settings/**` and `test/auth/**` (domain, application, mapping). — make test-dart not run (not selected); dart format applied
- [x] CP5 — Wiring, screens, routing: steps 34–40; `make lint` clean, and `make test` green including `route_guard_test.dart`, `app_test.dart`, `login_screen_test.dart` and `goals_form_test.dart`. — make lint and make test not run (not selected): none of the Dart code from steps 19-40 has been compiled, analysed or tested; dart format applied. Recommend running make lint and make test before review
- [x] CP6 — Docs and final light verification: steps 41–43; `make check-contract`, `make lint` and `make test` green. — docs updated (PRD, ARCHITECTURE, READMEs); make check-contract, make lint and make test not run (not selected)

### Risks & Mitigations
- **Email confirmation hides "already registered".** Supabase returns a fake user with empty `identities` and no error.
  - Mitigation: `isExistingUserSignUp` maps that signal to `EmailAlreadyRegistered`, and it is unit-tested (step 31).
  - Mitigation: if a GoTrue version returns `user_already_exists` instead, the code path covers that too.
- **GoTrue asymmetric key configuration differs by version.** An HS256 default would make the API reject every token (D-65).
  - Mitigation: pin the tag and check the variable in step 14.
  - Mitigation: if `GOTRUE_JWT_KEYS` is absent in that tag, pick a newer tag that has it; never switch the API to HS256.
- **Another user's goals become reachable.**
  - Mitigation: the `Repository` methods require `userID`; the transport reads it only from the context; the isolation repository test runs locally (step 9).
  - Mitigation: `lean-review` checks every SQL string for `user_id = $1`.
- **The JWT `sub` has no `auth.users` row** (a user created in another Auth instance, e.g. the hosted project against the local DB). The FK fails and PUT returns 500.
  - Mitigation: local dev pairs local GoTrue with the local DB.
  - Mitigation: documented in the README. M7 deletion cascades rows.
- **go_router redirect loops or flicker** while auth and goals load.
  - Mitigation: `redirectFor` is a pure function with a no-loop test (step 34); `/start` absorbs `loading` and `unknown`.
- **PKCE confirmation opened on another device** confirms the email but creates no session on the phone.
  - Mitigation: the check-email text says to open the link on this phone; the user can then sign in with the password.
- **Release build without `INTERNET`, or a blocked cleartext local stack.**
  - Mitigation: step 40 adds `INTERNET` to the main manifest and cleartext only to debug; iOS gets `NSAllowsLocalNetworking`.
- **Google and Apple cannot run against local GoTrue.**
  - Mitigation: the buttons show "Sign-in failed. Try again." locally.
  - Mitigation: verified on the hosted project by the user (Success Checklist).

## Test Strategy
**Light** (run during implementation; the user picks which):
- **Go unit tests:**
  - `domain/goals_test.go` (BR-003 boundaries).
  - `application/goals_test.go` (clock, isolation on the fake, no repository call when invalid).
  - `transport/handler_test.go` (200/400/401/404/500 bodies and codes).
  - `router_test.go` (JWT on settings, JSON 400 on a malformed body).
  - `limits_contract_test.go` (AD6).
- **Go repository test:** `infrastructure/repository_test.go` against local Postgres (`TEST_DATABASE_URL`, skipped otherwise and in CI). It covers BR-001 isolation and the upsert.
- **Flutter unit tests:**
  - Settings: domain goals rules, use cases on fakes, `mapGoalsError`.
  - Auth: `Email`, `Password`, use cases on `FakeAuthGateway`, `mapAuthError`, `isExistingUserSignUp`.
  - App: `redirectFor` table, `AppConfig.missingKeys`, theme contrast, `limits_contract_test`.
- **Flutter widget tests:** login error texts, goals form range error and Save enabled state, app locale `pl` and dark theme (FR-017).

**Heavy** (not run in implementation; for `lean-review` or the user):
- `make gen` leaves no diff, the API image builds and the Flutter app builds.
- Manual run on the local stack:
  - `make db-reset`, then sign up, open the link in Mailpit, land on the goals gate, save goals, kill and restart the app (still signed in, goals shown).
  - Forgot password, Mailpit link, new password, sign in.
  - Sign out.
  - Airplane mode on login gives "No connection. Try again.".
- Polish and English, light and dark, 200% font at 360 dp.
- Google and Apple on Android and iOS against the hosted project.
- **For `/lean-e2e`:**
  - Email sign-up reaches the check-email screen and, after confirmation, the goals gate.
  - kcal 499 on the goals screen shows the range error and keeps Save disabled.
  - A signed-in user who restarts the app lands on the Diary without signing in.

## Success Checklist
- [ ] All success criteria met (with evidence in the Implementation Log)
- [ ] Lint and unit tests clean (implementation)
- [ ] Heavy checks green when run (review): `make gen` no diff, API image builds, app builds
- [ ] Code review approved
- [ ] Documentation updated: PRD §11, §12, §20 (D-71–D-74), version; ARCHITECTURE Layout + AD11; README files
- [ ] No regressions in Polish and English, light and dark
- [ ] User action: create the hosted Supabase project (`test`, D-52). Confirm it signs tokens with asymmetric JWT signing keys (ES256/RS256), not legacy HS256 (D-65).
- [ ] User action: in Supabase Auth, turn Email on with "Confirm email" on and set the minimum password length to 8. Add `io.github.example.leantracker://auth-callback` to the redirect URLs.
- [ ] User action: Google Cloud OAuth client and Apple Services ID, key and return URL. Enable the Google and Apple providers in Supabase.
- [ ] User action: fill `apps/mobile/env/local.json` (git-ignored) with the hosted URL and anon key for social tests. Set `SUPABASE_JWKS_URL` for the API when it runs against the hosted project.
- [ ] User action: on a device, sign in with Google and Apple on Android and iOS.
- [ ] User action: commit (ask where, per CLAUDE.md) and push; open a PR with `Closes #<n>`

## Timeline & Estimates
- Phase 1 (implementation): ~18 hours (API 4, local auth stack 3, mobile logic 5, screens, routing and theme 6)
- Phase 2 (testing): ~5 hours
- Phase 3 (review + polish): ~4 hours
- **Total**: ~27 hours, plus buffer for GoTrue key configuration and DESIGN token extraction

## Open Questions
- [ ] GoTrue tag and asymmetric-key variable name: verified and recorded at step 14. This is not a product decision.
- [ ] GitHub issue number for the PR (`Closes #<n>`): asked at PR time.

## Implementation Log
- Decision: Local auth in M2: local Supabase Auth (GoTrue) in compose (2026-11-27)
- Decision: Goals storage in M2: API only, no local cache until M3
- Decision: Google and Apple sign-in: Supabase OAuth through the browser
- Decision: Email confirmation on sign-up: on, with a check-email screen; texts proposed by Claude and added to PRD §11
- Decision: Local mail catcher: Mailpit in compose
- Decision: Signed-in user without goals: goals screen before the diary
- Decision: Password reset: in M2
- Decision: Deep link: custom scheme `io.github.example.leantracker://auth-callback`
- Decision: Error codes: generic (`VALIDATION_ERROR`, `SETTINGS_NOT_FOUND`, `INTERNAL_ERROR`)
- Decision: Settings payload: one `Settings` schema, no `updated_at`
- Decision: Local auth stack start: part of `make up`
- Decision: New dependencies approved: `flutter_secure_storage`, dev `yaml`
- Decision: workspace: worktree (feature/03-auth-onboarding-settings from main @ b59fd19; main checkout has only untracked specs/03 at start)
- Decision: checks: none (lint and unit tests not selected; no check run during implementation)
- Step 1 — started
- Step 1 — done — files: apps/api/openapi.yaml — settings paths, InternalError, Settings, ErrorCode values, version 0.2.0
- Step 2 — started
- Step 2 — done — files: apps/api/internal/gen/openapi/openapi.gen.go, apps/mobile/openapi.yaml, apps/mobile/lib/gen/** — sync-contract + make gen ran; Go names present; Dart SettingsClient and Settings generated; flutter gen-l10n not yet (step 21)
- Step 3 — started
- Step 3 — done — files: apps/api/internal/kernel/limits/limits.go, apps/api/internal/kernel/clock/clock.go — four goal constants (BR-003), Clock + System
- Step 4 — started
- Step 4 — done — files: apps/api/internal/kernel/limits/limits_contract_test.go, apps/api/go.mod — AD6 test via kin-openapi; go mod tidy made kin-openapi direct (test not run: no checks selected)
- Step 5 — started
- Step 5 — done — files: apps/api/internal/settings/internal/domain/goals.go — Goals, Field, OutOfRangeError, ErrNotFound, NewGoals, Repository
- Step 6 — started
- Step 6 — done — files: apps/api/internal/settings/internal/domain/goals_test.go — table-driven BR-003 boundaries, first failing field (not run: no checks selected)
- Step 7 — started
- Step 7 — done — files: apps/api/internal/settings/internal/application/get_goals.go, save_goals.go, goals_test.go — GetGoals, SaveGoals (validate then upsert with clock UTC), fake-repo tests (not run: no checks selected)
- Step 8 — started
- Step 8 — done — files: apps/api/internal/settings/internal/infrastructure/repository.go — Querier, NewRepository, Get/Upsert with bound params and explicit columns
- Step 9 — started
- Step 9 — done — files: apps/api/internal/settings/internal/infrastructure/repository_test.go — skipped unless TEST_DATABASE_URL; BR-001 isolation, single-row upsert, not found (not run)
- Step 10 — started
- Step 10 — done — files: internal/settings/internal/transport/handler.go, internal/settings/internal/transport/handler_test.go — GetSettings/PutSettings with 401/404/400/500 mapping; 6 httptest cases (not run: no checks selected)
- Step 11 — started
- Step 11 — done — files: apps/api/internal/settings/settings.go — New(db Querier, clk) *Handler; aliases Handler and Querier so cmd/api can name them; comment cites AD11
- Step 12 — started
- Step 12 — done — files: apps/api/internal/platform/httpapi/router.go, router_test.go, health_test.go — NewHandler(v, StrictServerInterface) + JSON badRequest/internalError; tests: settings 401 without/expired token, malformed PUT -> 400 JSON (not run)
- Step 13 — started
- Step 13 — done — files: apps/api/cmd/api/server.go, apps/api/cmd/api/main.go — composite server embeds HealthServer and settings.Handler; main wires settings.New(pool, clock.System{})
- Step 13 — note: composite type named apiServer (not server) so it does not clash with the local http.Server variable in run()
- Step 14 — started
- Step 14 — done — files: apps/api/cmd/devjwk/main.go — ES256 JWK writer, O_EXCL. Pinned: supabase/auth:v2.199.0, nginx:1.30.8-alpine, axllent/mailpit:v1.34.0. Verified in v2.199.0 source: GOTRUE_JWT_KEYS is a JSON ARRAY of private JWKs (not {keys:[...]}), so devjwk writes an array; GOTRUE_JWT_SECRET is still required (local-only value); JWKS at /.well-known/jwks.json; image has sh+cat, CMD [auth], user supabase (key file 0644)
- Step 15 — started
- Step 15 — done — files: local/auth-gateway.conf — nginx server block: /auth/v1/ -> auth:9999, everything else 404
- Step 16 — started
- Step 16 — compose.yaml: auth, auth-gateway, mailpit (profile auth); api JWKS default -> auth-gateway. Compose config check pending
- Step 16 — done — files: compose.yaml — auth (supabase/auth:v2.199.0), auth-gateway (nginx:1.30.8-alpine, 127.0.0.1:54321), mailpit (axllent/mailpit:v1.34.0, 127.0.0.1:8025), api JWKS default -> auth-gateway; docker compose --profile auth --profile app config -q passes
- Step 17 — started
- Step 17 — done — files: Makefile — auth-keys (devjwk, skipped when key exists), up (auth profile), down (both profiles), db-reset (down -v both, db only, stub+migrations, then up), lint-dart paths, gen-dart gen-l10n, .PHONY; make -n dry-run OK; mailpit readyz subcommand confirmed in v1.34.0
- Step 18 — started
- Step 18 — done — files: .env.example, apps/api/.env.example — JWKS comments: local host URL, compose default, hosted URL
- CP2 note corrected: an earlier note wrongly cited make check-contract; that check was not run in CP2.
- Decision: checks: still none for CP3 onward (question re-asked, no selection given)
- Step 19 — started
- Step 19 — done — files: apps/mobile/pubspec.yaml, apps/mobile/pubspec.lock — added supabase_flutter ^2.18.3, flutter_secure_storage ^11.2.0, intl ^0.20.2, flutter_localizations (sdk), dev yaml ^3.1.4; generate: true; Nunito fonts entry (Regular, SemiBold 600, Bold 700, ExtraBold 800: weights confirmed against boards in step 23); description set
- Step 20 — started
- Step 20 — done — files: apps/mobile/assets/fonts/Nunito-Variable.ttf, apps/mobile/assets/fonts/OFL.txt, apps/mobile/pubspec.yaml — DEVIATION (user-approved): googlefonts/nunito has no releases or static TTFs; shipped official variable font Nunito[wght].ttf renamed Nunito-Variable.ttf + OFL.txt; pubspec declares one asset; weight via FontVariation('wght') in lib/ui (step 23)
- Step 21 — started
- Step 21 — done — files: apps/mobile/l10n.yaml, apps/mobile/lib/l10n/app_en.arb, app_pl.arb, app_localizations*.dart — 51 keys EN+PL (EN with @ descriptions); gen-l10n output committed in lib/l10n (synthetic-package: false); EN texts checked against PRD UF-001/FR-001/FR-002
- Step 22 — started
- Step 22 — done — files: apps/mobile/lib/kernel/limits/limits.dart, apps/mobile/test/kernel/limits_contract_test.dart — Limits (goal ranges, passwordMinLength 8); contract test reads apps/mobile/openapi.yaml with yaml (not run: no checks selected)
- Step 23 — started
- Step 23 — done — files: apps/mobile/lib/ui/tokens.dart, apps/mobile/lib/ui/theme.dart, apps/mobile/test/ui/theme_test.dart — Tokens decoded from docs/DESIGN.html (2-level gzip+base64 bundle; inner __bundler/template of 14 boards; .light/.dark CSS variables identical on all boards; radii 18/20/28/32/24, heights 52/56/48; weights 400/600/700/800), AppPalette ThemeExtension + AppRadii/AppSpacing/AppWeights, light/dark Material 3 themes with Nunito variable axis; contrast verified >=4.5 for all pairs by script and in test (tests not run). Mascot SVG in Logowanie/Cele is plain shapes (circles, paths): drawable with CustomPainter in step 37
- Step 24 — started
- Step 24 — done — files: apps/mobile/env/example.json, apps/mobile/lib/app/config.dart, apps/mobile/test/app/config_test.dart — AppConfig (fromEnvironment x3, authCallbackUrl, missingKeys) + pure missingConfigKeys for tests; example.json has placeholders only (not run)
- Formatting: ran dart format (not a check) on touched Dart paths at the end of CP3
- Step 25 — started
- Step 25 — done — files: apps/mobile/lib/settings/domain/goals.dart, apps/mobile/test/settings/domain/goals_test.dart — Goals, GoalField (min/max from Limits), GoalError, sealed GoalsInput, validateGoals; boundaries, empty, non-integer, all valid (not run). Domain has no framework import (no @immutable)
- Step 26 — started
- Step 26 — done — files: apps/mobile/lib/settings/application/goals_repository.dart, load_goals.dart, save_goals.dart, apps/mobile/test/settings/application/goals_use_cases_test.dart — Port + sealed GoalsLoad/GoalsSave, LoadGoals, SaveGoals (validate first). DEVIATION: GoalsSave also has GoalsInvalid(errors), returned only by the use case, so SaveGoals needs no extra result type (not run)
- Step 27 — started
- Step 27 — done — files: apps/mobile/lib/settings/infrastructure/api_goals_repository.dart, goals_error_mapping.dart, apps/mobile/test/settings/infrastructure/goals_error_mapping_test.dart — ApiGoalsRepository over SettingsClient; pure mapGoalsError(status, code, type) -> GoalsFailure{missing,rejected,unavailable}; load: unavailable/rejected -> GoalsUnavailable; save: unavailable/missing -> GoalsOffline (not run)
- Step 28 — started
- Step 28 — done — files: apps/mobile/lib/settings/settings.dart — exports domain, port + results, use cases, ApiGoalsRepository; the screens are added to this file in step 37
- Step 29 — started
- Step 29 — done — files: apps/mobile/lib/auth/domain/email.dart, password.dart, auth_failure.dart, auth_status.dart, apps/mobile/test/auth/domain/email_test.dart, password_test.dart — Email.tryParse / Password.tryParse (null on invalid, instead of throw), sealed AuthFailure x8, AuthStatus x5; toString hides values; 7 rejected, 8 accepted, empty, trim (not run)
- Step 30 — started
- Step 30 — done — files: apps/mobile/lib/auth/application/auth_gateway.dart, sign_up.dart, sign_in.dart, sign_in_with_provider.dart, request_password_reset.dart, set_new_password.dart, sign_out.dart, apps/mobile/test/auth/application/auth_use_cases_test.dart — Port (SocialProvider, sealed AuthResult), six use cases parse raw strings first; FakeAuthGateway tests: 7-char sign-up never calls gateway, invalid email, already-registered passes through, sign-out (not run)
- Step 31 — started
- Step 31 — done — files: apps/mobile/lib/auth/infrastructure/auth_error_mapping.dart, apps/mobile/test/auth/infrastructure/auth_error_mapping_test.dart — Plan named it infrastructure/auth_error_mapping.dart (spec step 31 and Key Changes). mapAuthError(code, statusCode) by code, mapAuthException (SocketException/AuthRetryableFetchException -> NoConnection), isExistingUserSignUp(0); every code in Key Changes covered (not run)
- Step 32 — started
- Step 32 — done — files: apps/mobile/lib/auth/infrastructure/supabase_auth_gateway.dart, secure_session_storage.dart — Gateway over GoTrueClient (emailRedirectTo/redirectTo = AppConfig.authCallbackUrl; status from onAuthStateChange; recovering is sticky until userUpdated/signOut; sign-up without session -> awaitingConfirmation; empty identities -> EmailAlreadyRegistered); LocalStorage over flutter_secure_storage; no logging of emails/passwords/tokens. APIs checked against gotrue 2.27.3 / supabase_flutter 2.18.3 sources; not compiled (no checks selected). Note: PKCE code verifier still uses the SDK default async storage (short-lived, not the session)
- Step 33 — started
- Step 32 — fix: gateway takes callbackUrl via constructor (module must not import app/ config); app/ passes AppConfig.authCallbackUrl in step 35
- Step 33 — done — files: apps/mobile/lib/auth/auth.dart — exports port, use cases, domain types, gateway, storage; the screens are added in step 36
- Step 34 — started
- Step 34 — done — files: apps/mobile/lib/app/route_guard.dart, apps/mobile/test/app/route_guard_test.dart — GoalsStatus, Routes (shared paths), pure redirectFor; DEVIATION: signedIn+saved on /forgot-password and /new-password also go to /diary (else the user is stuck after setting a new password); no-loop test over all 5x4x10 combinations (not run)
- Step 35 — started
- Step 35 — done — files: apps/mobile/lib/app/bootstrap.dart, http_client.dart, providers.dart, lib/main.dart — bootstrap (config check -> ConfigErrorApp, Supabase.initialize PKCE + SecureSessionStorage), createApiDio (10 s, Bearer from gateway), providers: gateway, authStatus, use cases, dio, restClient, repository, GoalsNotifier (watches auth status: reloads after sign-in/out; save replaces state), goalsStatusProvider -> GoalsStatus. main is Future<void> main() => bootstrap() (not run)
- Step 36 — started
- Step 36 — progress: shared widgets lib/ui/mascot.dart (CustomPainter from the board's plain shapes), app_text_field.dart, app_buttons.dart written; screens next
- Step 35 — rework (during step 36): screens need use cases but presentation must not import app/ (composition root). Moved use-case providers to lib/auth/presentation/auth_providers.dart and lib/settings/presentation/goals_providers.dart (authGatewayProvider and goalsRepositoryProvider are override points); app/providers.dart now holds appOverrides() (real adapters), authStatusProvider, dioProvider, restClientProvider, goalsStatusProvider (invalidates goalsProvider on auth status change, so GoalsNotifier no longer watches auth: settings does not import auth, AD3). Both public files export these. DEVIATION from plan wording 'providers.dart (AD9) has goalsProvider': goalsProvider is declared in settings, composed in app
- Step 36 — done — files: apps/mobile/lib/auth/presentation/{auth_controller,auth_failure_text,login_screen,check_email_screen,forgot_password_screen,new_password_screen,auth_providers}.dart, apps/mobile/lib/ui/{mascot,app_text_field,app_buttons}.dart, apps/mobile/lib/l10n/app_{en,pl}.arb, apps/mobile/lib/auth/auth.dart — One AuthController (Notifier, autoDispose) for all auth screens, widgets send intents; screens take navigation callbacks (no go_router/app import); authFailureText exhaustive; Semantics on fields/buttons (fields via AppTextField label, buttons via text), scrollable column. Added 2 ARB keys not in the plan table: mascotLabel and settingsEditGoals (a11y labels from DESIGN: 'Borówka, maskotka aplikacji', 'Edytuj cele'). ARB output regenerated at the end of CP5 (make gen-dart); not compiled (not run)
- Step 37 — started
- Step 37 — done — files: apps/mobile/lib/settings/presentation/{goals_form,goals_screen,edit_goals_screen,settings_screen}.dart, apps/mobile/lib/app/shell_scaffold.dart, apps/mobile/lib/app/diary_placeholder_screen.dart, apps/mobile/lib/settings/settings.dart — One GoalsForm for both screens (Save enabled only when all four valid; range errors as soon as a value is invalid; empty fields not scolded); onboarding mascot drawn from plain shapes (64 dp, left eye open as on the Cele board); Settings has Goals (edit button, tooltip settingsEditGoals), Language and theme info, Sign out, no Reminders/Delete (M7). Settings values composed as '<n> <unit>' from ARB unit keys. Bottom bar is Material 3 NavigationBar; pill styling via theme in step 38 (not run)
- Step 38 — started
- Step 38 — done — files: apps/mobile/lib/app/router.dart, app.dart, start_screen.dart, apps/mobile/lib/ui/theme.dart — Routes: /start /login /check-email /forgot-password /new-password /goals /auth-callback (redirect to /start) + StatefulShellRoute (/diary placeholder, /settings + /settings/goals); guard = redirectFor with refreshListenable bumped by authStatus and goalsStatus; app: themes light/dark, ThemeMode.system, delegates, supportedLocales [en, pl], en fallback. New file lib/app/start_screen.dart (holding screen with error + retry, plan §route_guard) and nav bar pill theme in ui/theme.dart (not run)
- Step 39 — started
- Step 39 — done — files: apps/mobile/test/support/fakes.dart, test/app/app_test.dart, test/auth/presentation/login_screen_test.dart, test/settings/presentation/goals_form_test.dart, test/auth/application/auth_use_cases_test.dart, test/settings/application/goals_use_cases_test.dart — Widget tests via provider overrides (authGatewayProvider, goalsRepositoryProvider) with shared fakes (unit tests now reuse them): signed-out login, pl locale 'Zaloguj się', de falls back to en, dark theme, goals gate, Diary for signed-in with goals, check-email; login errors (7-char password, invalid email, already registered, no connection); goals form (kcal 499, macro 1001, valid enables Save) (not run: no checks selected)
- Step 40 — started
- Step 40 — done — files: apps/mobile/android/app/src/main/AndroidManifest.xml, android/app/src/debug/AndroidManifest.xml, ios/Runner/Info.plist, lib/app/router.dart — Main manifest: INTERNET + VIEW/BROWSABLE intent-filter (scheme io.github.example.leantracker, host auth-callback); debug manifest: usesCleartextTraffic; Info.plist: CFBundleURLTypes, NSAllowsLocalNetworking, CFBundleLocalizations [en, pl]; all three parse as XML. Router also got a '/' -> /start redirect (a custom-scheme link without path reaches go_router as '/')
- Step 41 — started
- Step 41 — done — files: docs/PRD.md — UF-001 (step 2a, forgot-password flow, new error texts), UF-006 M2 scope note, FR-001 criterion 1, FR-002 criterion 2 note, D-71..D-74, version 1.2
- Step 42 — started
- Step 42 — done — files: docs/ARCHITECTURE.md, README.md, apps/mobile/README.md — ARCHITECTURE: Layout (l10n, kernel/limits, env, assets/fonts, cmd/devjwk, kernel clock/limits, compose profiles, local/auth-gateway.conf), AD9 amended (module-declared providers + app overrides), AD11 added; README: make up/auth-keys/db-reset, env/local.json, Mailpit, 10.0.2.2, hosted-only social sign-in; mobile README run command
- Step 43 — started
- Step 43 — done — files: none — make check-contract, make lint and make test NOT run (no checks selected). Coverage by tests that were written but never executed: FR-001 criteria 1-2 (sign_up/login_screen/app tests), FR-002 criterion 1 (goals_form_test, goals_test, handler_test). Manual or /lean-e2e: FR-001 criterion 3 (session restore), FR-002 criterion 2 (Diary shows goals, from M3; in M2 Settings shows them)
- Change after review (user request): no `local/auth-gateway.conf` file. GoTrue has no path-prefix option (v2.199.0 source) and the SDK hard-codes `/auth/v1`, so the nginx gateway stays but its config is written by the container command in compose.yaml (compose v2.12.2 lacks `configs.content`). `nginx -t` passes on the generated config. File removed, ARCHITECTURE Layout updated.
- Change after lint/test: make lint-go, test-go, lint-dart, test-dart now run green (Go: transport test needed the full server interface and devjwk lint fixes; Dart: publishableKey, positional gateway callback URL, unused enum value, test import).
- Handoff — mode: worktree — branch: feature/03-auth-onboarding-settings — base: b59fd19 — checks: none — changed: .env.example, Makefile, README.md, compose.yaml, local/auth-gateway.conf, apps/api/.env.example, apps/api/openapi.yaml, apps/api/go.mod, apps/api/cmd/api/{main.go,server.go}, apps/api/cmd/devjwk/main.go, apps/api/internal/gen/openapi/openapi.gen.go, apps/api/internal/kernel/{clock,limits}/, apps/api/internal/platform/httpapi/{router.go,router_test.go,health_test.go}, apps/api/internal/settings/**, apps/mobile/{README.md,l10n.yaml,openapi.yaml,pubspec.yaml,pubspec.lock,assets/,env/example.json}, apps/mobile/android/app/src/{main,debug}/AndroidManifest.xml, apps/mobile/ios/Runner/Info.plist, apps/mobile/lib/{main.dart,app/,auth/,settings/,kernel/,ui/,l10n/,gen/}, apps/mobile/test/**, docs/PRD.md, docs/ARCHITECTURE.md, specs/03-auth-onboarding-settings.md — preexisting: none (main checkout had only the untracked spec) — checkpoints: 6/6 (none verified by a run: no checks selected)
