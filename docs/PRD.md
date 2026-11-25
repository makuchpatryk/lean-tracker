# Lean Tracker — PRD

**Version:** 1.0 | **Date:** 2026-11-24 | **Status:** Ready for implementation

# Part I — Business

## 1. Problem & Goal
- **Who has the problem:** The author and a small group of friends (about 50 users at most) who want to track daily calorie and macronutrient intake against personal daily limits.
- **Current solution / workaround:** None. The group does not count calories today.
- **Cost of the problem:** N/A — confirmed by user.
- **Goal / target outcome:** Own mobile app (Android and iOS) that counts kcal, protein, fat and carbohydrates every day against user-defined daily limits, with fast product entry through barcode scan, favorites, recent products and quick add.
- **Why now:** N/A — confirmed by user.

## 2. Value Proposition
- **For:** the author and friends invited to internal testing.
- **Who need:** to log meals fast and see remaining daily kcal and macros.
- **The product:** Lean Tracker is a mobile calorie and macro diary with barcode scanning, favorites, recents, offline mode.
- **Unlike current solution:** there is no current solution; the product is owned by the author, has no ads, no payments and no premium tier.

## 3. Users & Roles
| Role / Persona | Goals | Pays / Uses | Permissions |
|----------------|-------|-------------|-------------|
| User (single role) | Log food, track daily kcal and macros against own limits, view last 7 days | Uses; does not pay. The author bears all costs | Reads and writes only own data. Reads shared own-products created by others. No admin role exists |

## 4. Business Model & Monetization
- **Revenue model:** None. The project has no revenue; the author pays all costs.
- **Pricing:**
| Tier | Price | Billing period | Includes | Limits |
|------|-------|----------------|----------|--------|
| Single free tier | 0 PLN | N/A | All MVP features | None |
- **Trial / free plan:** The app is free for all users.
- **Refunds / cancellation:** N/A — no payments exist.
- **Cost drivers:**
  - Variable: none in the MVP.
  - Fixed: Apple Developer Program (99 USD per year), Google Play developer account, Google Cloud Run (within free tier expected), Supabase Free plan (0 USD).

## 5. Business Rules

### BR-001: Single role, data isolation
- **Rule:** The system must allow a user to read, create, update and delete only the data that user owns. The system must not expose any other user's diary entries, goals, favorites, recents or settings.
- **Applies to:** User; all entities except shared products.
- **Exceptions:** Own products with `is_shared = true` are readable by all authenticated users (see BR-009).

### BR-002: Daily goals set manually
- **Rule:** The user must set four daily goals manually: kcal, protein (g), fat (g), carbohydrates (g). The system must not calculate goals from body data. The system must not collect weight, height, age or sex.
- **Applies to:** User.
- **Exceptions:** None.

### BR-003: Goal and quantity limits
- **Rule:** Daily kcal goal must be an integer from 500 to 10000. Daily protein, fat and carbohydrate goals must be integers from 0 to 1000. Entry quantity must be a number from 0.1 to 10000 with at most one decimal place. Product values per 100 g or 100 ml must be numbers from 0 to 9999 for kcal and from 0 to 100 for protein, fat and carbohydrates.
- **Applies to:** User input and imported products.
- **Exceptions:** None.

### BR-004: Diary day boundary
- **Rule:** A diary day must start at 00:00 and end at 23:59:59 in the local time zone of the user device. An entry belongs to the day stored in its `entry_date` field, chosen by the user (default: current local date).
- **Applies to:** Diary entries.
- **Exceptions:** None.

### BR-005: Meal categories
- **Rule:** Every diary entry must belong to exactly one fixed meal category: `breakfast`, `lunch`, `dinner`, `snack`. The system must not allow custom categories.
- **Applies to:** Diary entries.
- **Exceptions:** None.

### BR-006: Units
- **Rule:** The user must enter the quantity of an entry in the product base unit (`g` or `ml`) or in `serving`. The unit `serving` must be available only if the product has `serving_size` defined. Nutrition per entry must be calculated as `value_per_100 * quantity_in_base_unit / 100`, where `quantity_in_base_unit = quantity * serving_size` for `serving`. The system must not convert between g and ml.
- **Applies to:** Diary entries.
- **Exceptions:** None.

### BR-007: Entry nutrition snapshot
- **Rule:** On saving an entry, the system must copy product name, base unit and values per 100 g/ml into the entry. Later changes to the product must not change existing entries.
- **Applies to:** Diary entries.
- **Exceptions:** None.

### BR-008: Product not found by barcode
- **Rule:** If a scanned barcode has no product in Open Food Facts and no own product with that barcode visible to the user, the system must open the own-product form with the barcode pre-filled. The user must enter name and values per 100 g/ml manually.
- **Applies to:** Barcode scan.
- **Exceptions:** None.

### BR-009: Own-product visibility
- **Rule:** An own product must be private by default (`is_shared = false`). The author must be able to switch `is_shared` per product at any time. A shared product must be visible in name search and barcode lookup for all authenticated users. Only the author may edit or delete a product. Setting `is_shared = false` must remove the product from other users' search results; entries already saved by other users must remain unchanged (BR-007).
- **Applies to:** Own products.
- **Exceptions:** None.

### BR-010: Favorites and recents
- **Rule:** The user must be able to mark any product as favorite. The system must keep a list of the 20 most recently used unique products per user, ordered by last use descending. Using a product in a diary entry must update its recent position.
- **Applies to:** User.
- **Exceptions:** None.

### BR-014: Offline operation
- **Rule:** The app must allow, without network: creating, editing and deleting diary entries; viewing the diary and weekly summary; managing favorites; viewing recents; creating and editing own products; viewing products stored locally. The app must require network for: login, barcode lookup of products not stored locally, name search in Open Food Facts and shared products, account deletion. Offline changes must be synchronized when network returns. On conflict, the change with the latest `updated_at` must win.
- **Applies to:** App.
- **Exceptions:** None.

### BR-015: Weekly summary
- **Rule:** The weekly summary must show total kcal per day for the current day and the 6 days before it, the daily kcal goal as a reference line, and the average kcal over those 7 days. Days without entries must count as 0 kcal in the chart and must be excluded from the average.
- **Applies to:** User.
- **Exceptions:** If all 7 days have no entries, the average must display `—`.

### BR-016: Reminders
- **Rule:** The user must be able to set from 0 to 3 daily reminder times. Reminders must be local device notifications with fixed text. The system must not use server push.
- **Applies to:** User.
- **Exceptions:** None.

### BR-017: Account deletion
- **Rule:** The user must be able to permanently delete the account and all associated data in the app. Deletion must be immediate and irreversible. Shared own products of the deleted user must be deleted as well.
- **Applies to:** User.
- **Exceptions:** None.

## 6. Business Processes

### BP-001: Add product by barcode
1. User opens the add-entry screen and taps scan.
2. App scans the barcode.
3. App looks up the barcode in local storage, then through the API (own and shared products, then Open Food Facts).
4. App shows product with default quantity and meal category.
5. User confirms quantity, unit, meal category and date.
6. App saves the entry (BR-007) and updates recents (BR-010).
- **Statuses & allowed transitions:** N/A.
- **Exceptions:** product not found → BR-008; network missing and product not stored locally → error `OFFLINE_LOOKUP_UNAVAILABLE` with option to use name search of local products or add own product; scan permission denied → message with link to system settings.
- **Related rules:** BR-006, BR-007, BR-008, BR-010, BR-014.

### BP-002: Add product by name search
1. User types at least 2 characters.
2. App shows local products (favorites and recents first), then API results (own, shared, Open Food Facts).
3. User selects product and continues as in BP-001 step 5.
- **Exceptions:** no results → option to add own product; offline → only local results.
- **Related rules:** BR-009, BR-010, BR-014.

### BP-003: Quick add from favorites or recents
1. User opens add-entry screen.
2. App shows tabs Favorites and Recents.
3. User taps product; app shows quantity form with last used quantity and unit pre-filled.
4. User confirms; app saves entry.
- **Related rules:** BR-006, BR-010.

### BP-004: Copy meal
1. User opens a meal category of a day and taps copy.
2. User selects target date and target meal category.
3. App creates copies of all entries of the source meal in the target (new ids, `updated_at` now).
- **Exceptions:** source meal empty → copy action disabled.
- **Related rules:** BR-004, BR-005, BR-007.

### BP-006: Registration and first launch
1. User chooses email + password, Google or Apple.
2. App shows the goals screen (BR-002); user must save four goals to proceed.
3. App opens the diary.
- **Exceptions:** email already used → error; weak password → error (see FR-001).
- **Related rules:** BR-002, BR-003.

### BP-007: Account deletion
1. User opens Settings → Delete account.
2. App shows confirmation dialog stating deletion is permanent.
3. User re-authenticates (password for email accounts; provider login for Google/Apple).
4. API deletes all user data and the Supabase Auth user.
5. App clears local database and returns to login.
- **Exceptions:** offline → deletion unavailable.
- **Related rules:** BR-017.

## 7. Assumptions & Risks
### Assumptions (stated by user)
| # | Assumption | Validation method |
|---|------------|-------------------|
| A-1 | At least 80% of scanned barcodes are found in Open Food Facts or own/shared products | Not measured in the MVP (no analytics); to be measured after analytics is introduced (section 23) |
| A-2 | Adding a product by barcode takes at most 10 s from opening the app to saved entry | Not measured in the MVP (no analytics); to be measured after analytics is introduced (section 23) |
| A-3 | Friends log entries on at least 5 of 7 days per week | Not measured in the MVP (no analytics); to be measured after analytics is introduced (section 23) |

### Risks
| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| R-1 | N/A | N/A | No risks were declared by the user for the MVP (the AI cost risk moved to section 23) |

## 8. Success Metrics
| KPI | Target | Timeframe | Measurement |
|-----|--------|-----------|-------------|
| Time from app open to saved entry via scan | ≤ 10 s | Measured per event, evaluated after 30 days of use | Not measured in the MVP; see section 23 |
| Days with at least one entry per week per user | ≥ 5 of 7 | Rolling week, evaluated after 30 days of use | Not measured in the MVP; see section 23 |
| Barcode coverage | ≥ 80% scans with a product found | 30 days of use | Not measured in the MVP; see section 23 |

## 9. Constraints
- **Deadline:** none.
- **Team:** implemented only by an AI coding agent; the author approves.
- **Budget:** no variable costs in the MVP; fixed costs: Apple Developer 99 USD/year, Google Play developer account, Supabase Free (0 USD).
- **Scale:** the author and friends, about 50 users at most.
- **Distribution:** internal testing only (TestFlight, Google Play internal testing). No public store release.
- **Legal:** the app processes email and nutrition diary data; GDPR applies. Account deletion in app (BR-017) is required.
- **Existing systems to reuse:** Open Food Facts API, Supabase Auth and Postgres.

# Part II — Product

## 10. Scope
### 10.1 MVP
- Registration and login (email + password, Google, Apple).
- Daily goals (manual).
- Barcode scan, name search, own products (private/shared).
- Diary of the day with fixed meal categories, totals of kcal, protein, fat, carbohydrates, remaining vs goals.
- Favorites and recents (20).
- Copy meal.
- Weekly summary (last 7 days, kcal vs goal).
- Offline mode with synchronization.
- Local reminders (up to 3 per day).
- Polish and English UI; light and dark theme by system.
- Account deletion.

### 10.2 Post-MVP
- OCR of nutrition tables on device (Google ML Kit).
- AI meal-photo recognition (see section 23).
- Firebase Analytics with opt-in consent (see section 23).
- Web application for desktop browsers (same Go API and Supabase Auth; platform, framework and feature scope to be defined in a separate PRD before work starts).

### 10.3 Out of Scope
- Premium plan, payments, subscriptions, donations, ads.
- Goal calculator from body data.
- Water, weight, exercise tracking.
- Custom meal categories.
- Manual theme switch.
- Server push notifications.
- Admin role and admin panel.
- Public store release.
- Data export.
- Web application and tablet layouts in the MVP (web application is planned post-MVP, see 10.2).

## 11. User Flows

### UF-001: Registration
1. App shows login screen with fields email, password, buttons Sign up, Sign in, Google, Apple.
2. User taps Sign up and submits email and password.
3. App shows goals form (four fields); Save is enabled when all four are valid.
4. App opens the Diary.
- **Error states:** invalid email → "Enter a valid email address."; password shorter than 8 characters → "Password must have at least 8 characters."; email taken → "This email is already registered."; no network → "No connection. Try again."
- **Empty states:** N/A.

### UF-002: Diary
1. App shows today's date with arrows to move days and a date picker.
2. App shows summary card: consumed / goal for kcal, protein, fat, carbohydrates, and remaining kcal.
3. App shows four meal sections with entries, per-meal kcal, and a plus button.
4. User taps an entry to edit quantity, unit, meal, date, or delete it.
- **Error states:** save failure locally → "Could not save entry."
- **Empty states:** meal without entries shows "No entries" and the plus button.

### UF-003: Add entry
1. User taps plus in a meal section; app opens add screen with tabs Search, Favorites, Recents and buttons Scan, Own product.
2. User picks a product by scan, search, favorite or recent.
3. App shows quantity form (quantity, unit, meal, date) with live nutrition preview.
4. User taps Save; app returns to Diary.
- **Error states:** invalid quantity → "Enter a quantity from 0.1 to 10000."
- **Empty states:** Favorites empty → "No favorites yet"; Recents empty → "No recent products".

### UF-004: Own product
1. User taps Own product (or arrives from BR-008).
2. App shows form: name, brand (optional), barcode (optional), base unit (g/ml), kcal, protein, fat, carbohydrates per 100 base unit, serving size (optional), Share with others toggle (off by default).
3. User saves; product is available for entries.
- **Error states:** missing name → "Enter a product name."; value out of range → "Enter a value from 0 to {max}."; barcode already used by the user's own product → "You already have a product with this barcode."

### UF-005: Weekly summary
1. User opens Summary tab.
2. App shows bar chart of 7 days with goal line and average kcal.
- **Empty states:** no entries in 7 days → chart with zero bars and average "—".

### UF-006: Settings
1. Sections: Goals, Reminders (up to 3 times), Language follows system (no manual switch), Delete account, Sign out.
- **Error states:** adding a fourth reminder is disabled with message "Maximum 3 reminders."

## 12. Functional Requirements

### FR-001: Registration and login
- **Implements:** BP-006, BR-001
- **Description:** The system must support sign-up and sign-in with email + password, Google and Apple through Supabase Auth. The system must require passwords of at least 8 characters. The system must provide password reset by email.
- **Inputs / validation:** email (valid format), password (≥ 8 characters).
- **Edge cases:** Apple sign-in must be offered on iOS and Android; session must persist across app restarts.
- **Acceptance criteria:**
  - Given an unregistered email and a 8-character password, when the user submits sign-up, then an account is created and the consent screen is shown.
  - Given a password of 7 characters, when the user submits, then the error "Password must have at least 8 characters." is shown and no account is created.
  - Given a registered user, when the app restarts, then the user stays signed in.

### FR-002: Daily goals
- **Implements:** BR-002, BR-003
- **Description:** The system must store four daily goals per user and allow editing them in Settings.
- **Inputs / validation:** kcal integer 500–10000; protein, fat, carbohydrates integers 0–1000.
- **Edge cases:** goals changes apply to all days (no history of goals).
- **Acceptance criteria:**
  - Given kcal = 499, when the user saves, then the error "Enter a value from 500 to 10000." is shown.
  - Given valid goals, when the user saves, then the Diary shows the new goals.

### FR-003: Diary of the day
- **Implements:** BR-004, BR-005, BR-015 (totals), goal
- **Description:** The system must display entries of the selected day grouped by meal category with per-meal and per-day totals of kcal, protein, fat, carbohydrates, and remaining kcal (`goal - consumed`, negative values displayed with minus sign).
- **Inputs / validation:** date within any past or future day.
- **Edge cases:** day without entries shows zeros.
- **Acceptance criteria:**
  - Given entries of 300 kcal and 200 kcal and a goal of 2000, when the user opens the day, then consumed = 500 and remaining = 1500.

### FR-004: Entry CRUD
- **Implements:** BR-003, BR-005, BR-006, BR-007
- **Description:** The system must create, edit and delete diary entries. Fields: product snapshot, quantity, unit, meal category, entry date.
- **Inputs / validation:** quantity 0.1–10000, one decimal place; unit in {base unit, serving}; meal in fixed set.
- **Edge cases:** editing an entry must not change the product snapshot except quantity, unit, meal and date.
- **Acceptance criteria:**
  - Given a product with 200 kcal per 100 g, when the user saves 150 g, then the entry has 300 kcal.
  - Given a product with serving_size = 30 g and 100 kcal per 100 g, when the user saves 2 servings, then the entry has 60 g and 60 kcal.
  - Given an existing entry, when the product's values change later, then the entry's values remain unchanged.

### FR-005: Barcode scan
- **Implements:** BP-001, BR-008, goal
- **Description:** The system must scan EAN-13, EAN-8, UPC-A and UPC-E barcodes with the device camera and look up the product in this order: local storage, own products, shared products, Open Food Facts.
- **Inputs / validation:** barcode string of 8–13 digits.
- **Edge cases:** camera permission denied; product found in several sources — the order above decides.
- **Acceptance criteria:**
  - Given a barcode present in Open Food Facts, when scanned online, then the product is shown with values per 100 g/ml.
  - Given a barcode absent everywhere, when scanned, then the own-product form opens with the barcode pre-filled.
  - Given no network and a barcode not stored locally, when scanned, then the error `OFFLINE_LOOKUP_UNAVAILABLE` message is shown.

### FR-006: Name search
- **Implements:** BP-002, BR-009, BR-014
- **Description:** The system must search by name in local products, own products, shared products and Open Food Facts, and return at most 30 results ordered: favorites, recents, own, shared, Open Food Facts.
- **Inputs / validation:** query of at least 2 characters.
- **Edge cases:** offline returns only local products.
- **Acceptance criteria:**
  - Given a favorite product "Skyr", when the user searches "sky", then "Skyr" appears first.
  - Given a private product of another user, when the user searches its name, then it is not returned.

### FR-007: Open Food Facts mapping
- **Implements:** BR-003, BR-006
- **Description:** The API must map Open Food Facts fields to the product model: `product_name` → name, `brands` → brand, `nutriments.energy-kcal_100g`, `proteins_100g`, `fat_100g`, `carbohydrates_100g` → values per 100, `serving_quantity` → serving_size. Base unit must be `ml` when `product_quantity_unit` is `ml` or `l`, otherwise `g`. The API must discard products without name or without kcal value.
- **Edge cases:** missing protein, fat or carbohydrate values map to 0.
- **Acceptance criteria:**
  - Given an Open Food Facts product with `energy-kcal_100g = 52`, when mapped, then `kcal_per_100 = 52`.
  - Given an Open Food Facts product without kcal, when searching, then it is excluded from results.

### FR-008: Own products
- **Implements:** BR-008, BR-009, BR-003
- **Description:** The system must create, edit and delete own products with the `is_shared` toggle (default off).
- **Inputs / validation:** name 1–120 characters; brand 0–80; barcode 8–13 digits; base unit g or ml; kcal 0–9999; protein, fat, carbohydrates 0–100; serving_size 0.1–10000 optional.
- **Edge cases:** deleting a product must not delete existing entries (BR-007).
- **Acceptance criteria:**
  - Given a new product, when saved without changing the toggle, then `is_shared = false`.
  - Given a shared product, when the author sets the toggle off, then other users no longer find it.
  - Given a product used in entries, when deleted, then entries remain.

### FR-009: Favorites and recents
- **Implements:** BR-010
- **Description:** The system must let the user mark products as favorite and must keep 20 recent unique products.
- **Edge cases:** the 21st recent product removes the oldest.
- **Acceptance criteria:**
  - Given 20 recents, when a new product is used, then the list has 20 items and the oldest is removed.
  - Given a recent product used again, when listed, then it is first.

### FR-010: Copy meal
- **Implements:** BP-004
- **Description:** The system must copy all entries of one meal of a date to another meal and date.
- **Acceptance criteria:**
  - Given 3 entries in breakfast of 2026-01-01, when copied to lunch of 2026-01-02, then 3 new entries exist in that lunch and the sources remain.

### FR-011: Weekly summary
- **Implements:** BR-015
- **Description:** The system must show the 7-day kcal chart, goal line and average.
- **Acceptance criteria:**
  - Given entries on 3 of 7 days with 2000, 1800 and 2200 kcal, when the summary opens, then the average equals 2000 and empty days show 0 bars.

### FR-012: Reminders
- **Implements:** BR-016
- **Description:** The app must schedule up to 3 daily local notifications at user-set times with fixed text "Log your meals" (EN) / "Zapisz swoje posiłki" (PL).
- **Edge cases:** notification permission denied → message with link to system settings.
- **Acceptance criteria:**
  - Given a reminder at 20:00, when the time is reached, then a notification is shown on the device.
  - Given 3 reminders, when the user adds a fourth, then adding is blocked.

### FR-013: Offline and synchronization
- **Implements:** BR-014
- **Description:** The app must store data in a local Drift (SQLite) database and synchronize with the API when network is available. Every syncable record must carry `id` (client-generated UUID), `updated_at` and `deleted_at`. On conflict the latest `updated_at` wins. Deletions must propagate as `deleted_at`.
- **Edge cases:** the same entry edited on two devices — the later `updated_at` wins.
- **Acceptance criteria:**
  - Given offline mode, when the user adds an entry and later gets network, then the entry appears on the server within 30 s.
  - Given two edits of one entry with different `updated_at`, when both sync, then the later one is stored.

### FR-016: Account deletion
- **Implements:** BP-007, BR-017
- **Description:** The endpoint `DELETE /v1/account` must delete all user rows and the Supabase Auth user through the Supabase Admin API.
- **Acceptance criteria:**
  - Given a signed-in user who re-authenticated, when deletion is confirmed, then all rows of the user are removed and sign-in with the same credentials fails.

### FR-017: Localization and theme
- **Implements:** goal
- **Description:** The app must provide Polish and English strings selected by system locale (English when the system locale is neither). The app must follow the system light/dark theme.
- **Acceptance criteria:**
  - Given system language Polish, when the app starts, then all UI strings are in Polish.
  - Given system dark mode, when the app starts, then the dark theme is shown.

# Part III — Technical

## 13. Data Model
All tables are in Supabase Postgres. All timestamps are `timestamptz` in UTC. All `id` values are client-generated UUID v4 unless noted.

### user_settings
| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| user_id | uuid | yes | PK, FK auth.users | |
| goal_kcal | int | yes | 500–10000 | |
| goal_protein_g | int | yes | 0–1000 | |
| goal_fat_g | int | yes | 0–1000 | |
| goal_carbs_g | int | yes | 0–1000 | |
| updated_at | timestamptz | yes | | |
- **Relations:** one per user.
- **Retention / deletion:** deleted with the account.

### products
| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| id | uuid | yes | PK | |
| owner_id | uuid | yes | FK auth.users | own products only; Open Food Facts products are not stored server-side |
| name | text | yes | 1–120 chars | |
| brand | text | no | ≤ 80 chars | |
| barcode | text | no | 8–13 digits; unique per owner | |
| base_unit | text | yes | `g` or `ml` | |
| kcal_per_100 | numeric(6,1) | yes | 0–9999 | |
| protein_per_100 | numeric(5,1) | yes | 0–100 | |
| fat_per_100 | numeric(5,1) | yes | 0–100 | |
| carbs_per_100 | numeric(5,1) | yes | 0–100 | |
| serving_size | numeric(7,1) | no | 0.1–10000 | in base unit |
| is_shared | boolean | yes | default false | |
| updated_at | timestamptz | yes | | |
| deleted_at | timestamptz | no | | |
- **Relations:** many per user.
- **Retention / deletion:** deleted with the account; soft delete through `deleted_at`.

### diary_entries
| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| id | uuid | yes | PK | |
| user_id | uuid | yes | FK auth.users | |
| entry_date | date | yes | | local date |
| meal | text | yes | breakfast, lunch, dinner, snack | |
| product_name | text | yes | | snapshot |
| source | text | yes | `off`, `own`, `manual` | |
| source_ref | text | no | | barcode or product id |
| base_unit | text | yes | `g` or `ml` | snapshot |
| kcal_per_100 | numeric(6,1) | yes | | snapshot |
| protein_per_100 | numeric(5,1) | yes | | snapshot |
| fat_per_100 | numeric(5,1) | yes | | snapshot |
| carbs_per_100 | numeric(5,1) | yes | | snapshot |
| quantity | numeric(7,1) | yes | 0.1–10000 | as entered |
| unit | text | yes | base unit or `serving` | |
| serving_size | numeric(7,1) | no | | snapshot, required when unit = serving |
| updated_at | timestamptz | yes | | |
| deleted_at | timestamptz | no | | |
- **Relations:** many per user.
- **Retention / deletion:** deleted with the account.

### favorites
| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| id | uuid | yes | PK | |
| user_id | uuid | yes | FK | |
| product_key | text | yes | unique per user | `off:{barcode}` or `own:{product_id}` |
| product_snapshot | jsonb | yes | | name, base_unit, values per 100, serving_size |
| updated_at | timestamptz | yes | | |
| deleted_at | timestamptz | no | | |

### recents
| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| user_id | uuid | yes | PK part | |
| product_key | text | yes | PK part | same format as favorites |
| product_snapshot | jsonb | yes | | |
| last_quantity | numeric(7,1) | yes | | |
| last_unit | text | yes | | |
| last_used_at | timestamptz | yes | | the API keeps the 20 newest per user |
| updated_at | timestamptz | yes | | |

## 14. Auth & Access Control
- **Method:** Supabase Auth (email + password, Google, Apple). The Flutter app signs in through `supabase_flutter`. The Go API must verify the Supabase JWT (signature through project JWKS, `exp`, `aud`) on every request and read `user_id` from `sub`.
- **Session:** Supabase access token with refresh token stored in secure storage; the app refreshes automatically.
- **Data access:** Go connects to Postgres through a dedicated database role; every query on user tables must filter by `user_id` from the JWT. Row Level Security must be enabled on all tables with no policies for `anon` and `authenticated` roles, so direct access through Supabase REST is denied.
- **Access matrix:**
| Resource / Action | User (owner) | User (other) |
|-------------------|--------------|--------------|
| Own settings, entries, favorites, recents | read/write | none |
| Own product (private) | read/write | none |
| Own product (shared) | read/write | read |

## 15. Integrations
| Service | Purpose | Data exchanged | Failure handling |
|---------|---------|----------------|------------------|
| Open Food Facts API | Barcode lookup and name search | Barcode or query → product fields (FR-007) | Timeout 5 s; on failure return `OFF_UNAVAILABLE` and the app shows "Product database unavailable." with option to add own product |
| Supabase Auth | Sign-in, tokens, deletion | Credentials, JWT, admin delete | Errors displayed per UF-001 |
| Google and Apple sign-in | Social login | OAuth tokens via Supabase | Error "Sign-in failed. Try again." |

## 16. Platforms & UI
- **Platforms:** Android 10+ and iOS 16+ phones, portrait orientation.
- **Responsiveness:** phone screens from 360 dp width; tablets and landscape are not supported.
- **Languages:** Polish and English, selected by system locale.
- **Accessibility:** scaling with system font size up to 200%; Semantics labels on all interactive elements; text contrast ratio at least 4.5:1.
- **Design reference:** `docs/DESIGN.html` (bundled canvas, open it in a browser): 14 phone boards of 390 × 844 (Logowanie, Cele (pierwsze uruchomienie), Dziennik, Dodaj wpis, Skaner, Ilość, Własny produkt, Szczegóły posiłku, Kopiuj posiłek, Tydzień, Ustawienia, Usuwanie konta; Dziennik and Ilość also in dark). Screen layout, colors (light and dark palettes), the meal accent colors and the Nunito font come from it. Components are Material 3 themed with those tokens; light and dark theme follow the system; no other custom design system. Where the design and §11 differ in a text, §11 wins; where they differ in layout, the design wins.

## 17. Non-Functional Requirements

### NFR-001: Barcode lookup latency
- **Requirement:** From barcode detection to product display, p95 ≤ 4 s online.
- **Verification:** load test of the `/v1/products/barcode/{code}` endpoint and manual timing on a physical device.

### NFR-002: Local operations
- **Requirement:** Saving an entry locally must complete in ≤ 300 ms (p95) on a device with Android 10 or iOS 16.
- **Verification:** Flutter integration test with timing assertion.

### NFR-003: API availability
- **Requirement:** No availability target is defined beyond Cloud Run default behavior; cold start of the Go service must be ≤ 3 s.
- **Verification:** Manual measurement after deploy.

### NFR-004: Security
- **Requirement:** All traffic must use HTTPS. The Supabase service role key must exist only as a Cloud Run environment secret. The app must not contain any secret except the Supabase anon key and URL. Every API endpoint except health check must require a valid JWT.
- **Verification:** Unit tests for the JWT middleware; repository secret scan in CI.

### NFR-007: Scale
- **Requirement:** The system must support 50 users with up to 200 diary entries per user per month each within Supabase Free limits.
- **Verification:** Manual check of Supabase usage dashboard.

### NFR-008: Business rule tests
- **Requirement:** every business rule BR-xxx implemented in `domain` or `application` has a unit test that does not require network, database or Flutter widgets.
- **Verification:** unit tests run without external services.

## 18. Tech Stack
| Layer | Choice | Version (if fixed) |
|-------|--------|--------------------|
| Frontend | Flutter (Dart), Material 3, Drift (SQLite), supabase_flutter, mobile scanner plugin, local notifications plugin | latest stable at project start |
| Backend | Go REST API, OpenAPI 3 contract, generated Dart client | latest stable Go at project start |
| Database | Supabase Postgres (Free plan) + Supabase Auth | — |
| Hosting / Deployment | Google Cloud Run (Docker container) for the Go API; TestFlight and Google Play internal testing for the app | — |
| CI/CD | GitHub Actions: tests on every push; manual workflows for API deploy (with migrations) and mobile builds (see 18.2) | — |
| Testing | Unit tests for Go and Flutter (business rules BR-003, BR-006, BR-015, sync conflict resolution) | — |
- **Repo structure:** single monorepo with strictly separated applications and modules (see 18.1):
  - `/apps/mobile` — Flutter application.
  - `/apps/api` — Go API.
  - `/apps/web` — reserved for the post-MVP web application; must not be created in the MVP.
  - `/contracts/openapi` — OpenAPI file, the only contract between applications; the Dart client is generated from it.
  - `/db/migrations` — SQL migrations.
  - `/docs` — this PRD.
  - `/.github/workflows` — CI/CD.

### 18.1 Architecture
- **Style:** Clean Architecture in both `/apps/mobile` and `/apps/api`. Each application must be split into modules by business capability (`auth`, `settings`, `products`, `diary`, `favorites_recents`, `summary`, `reminders`, `sync`, `account`), and each module must contain the layers `domain`, `application`, `infrastructure`, `presentation` (mobile) or `transport` (API).
- **Dependency rule:** `domain` must not import any other layer, any framework package or any other module's internals. `application` must depend only on `domain` and on interfaces (ports) defined in `domain` or `application`. `infrastructure` and `presentation`/`transport` must depend inward only. Business rules BR-xxx must be implemented in `domain` or `application`.
- **Module boundaries:** a module must communicate with other modules only through its public interface (a single exported API per module: `lib/<module>/<module>.dart` in Flutter, the exported package API in Go; no imports of other modules' `internal` or `src` paths).
- **Application boundaries:** `/apps/mobile`, `/apps/api` and the future `/apps/web` must not import each other's code. They must share only the OpenAPI contract in `/contracts/openapi`. Code shared between applications must not exist outside generated clients.

### 18.2 Deployment & DevOps
Everything in this section is built in M8 (D-61). Until then the system runs and is tested locally only.

- **Environments:** exactly one environment, `test`: one Supabase project, one Cloud Run service for `/apps/api`. No production environment exists in the MVP.
- **Pipeline on every push and pull request (GitHub Actions):** Go unit tests, Flutter unit tests, repository secret scan. A failure must block merging into `main`.
- **API deployment:** a manually triggered GitHub Actions workflow (`workflow_dispatch`) run on `main`. It must execute in this order: (1) run tests, (2) apply SQL migrations from `/db/migrations` to the `test` Supabase project, (3) build the Go container image, (4) push the image to a container registry, (5) deploy it to Cloud Run. If any step fails, the workflow must stop and must not execute later steps.
- **Migrations:** forward-only SQL files, numbered in ascending order, applied by the pipeline with the Supabase CLI. A migration must not be edited after it has been applied.
- **Secrets:** stored in GitHub Secrets and injected into Cloud Run as environment variables at deploy time. Required secrets: `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_URL`, `DATABASE_URL`, `SUPABASE_JWKS_URL`. Secrets must not appear in the repository or in workflow logs.
- **Google Cloud access:** the workflow authenticates with a service account JSON key stored in GitHub Secrets. The service account must have only the roles required to deploy to Cloud Run and push images.
- **Mobile builds:** a manually triggered GitHub Actions workflow that builds the Android app bundle and the iOS archive and uploads them to Google Play internal testing and TestFlight. Signing keys, keystore, passwords and store credentials must be stored in GitHub Secrets.
- **Rollback:** the API must be rolled back by redeploying a previous container image through the same workflow with an image tag input.

## 19. Implementation Plan

### M1: Repo, database and API skeleton
- **Includes:** monorepo setup with the structure and module skeletons from 18.1, SQL migrations for all tables (section 13) applied to a local Postgres, Go service with JWT middleware and health endpoint, OpenAPI file, local run with Docker Compose. M1 works locally only: CI, deployment, hosted migrations and secrets (18.2) are built in M8 (D-61).
- **Depends on:** —
- **Definition of done:** a request without a valid JWT returns 401; migrations apply to an empty local Postgres; the API runs locally.

### M2: Auth, onboarding, settings
- **Includes:** FR-001, FR-002, FR-017, UF-001, UF-006 (goals, sign out).
- **Depends on:** M1.
- **Definition of done:** a user can sign up through all three methods, set goals and see them after restart; acceptance criteria of FR-001, FR-002 pass.

### M3: Local database, diary and entries
- **Includes:** Drift schema, FR-003, FR-004, UF-002, UF-003 (manual quantity form), BR-004–BR-007 unit tests.
- **Depends on:** M2.
- **Definition of done:** entries can be created, edited, deleted offline; totals match the FR-003 criterion.

### M4: Products, scan, search
- **Includes:** FR-005, FR-006, FR-007, FR-008, UF-004, BP-001, BP-002; API endpoints for products and Open Food Facts.
- **Depends on:** M3.
- **Definition of done:** acceptance criteria of FR-005–FR-008 pass on a physical device; NFR-001 measured.

### M5: Favorites, recents, copy meal, weekly summary
- **Includes:** FR-009, FR-010, FR-011, BP-003, BP-004, UF-005.
- **Depends on:** M4.
- **Definition of done:** acceptance criteria of FR-009–FR-011 pass.

### M6: Synchronization
- **Includes:** FR-013, sync endpoints, conflict resolution tests.
- **Depends on:** M5.
- **Definition of done:** acceptance criteria of FR-013 pass with two devices.

### M7: Reminders, account deletion
- **Includes:** FR-012, FR-016, UF-006 (reminders, deletion).
- **Depends on:** M6.
- **Definition of done:** acceptance criteria of FR-012, FR-016 pass.

### M8: Localization, accessibility, distribution
- **Includes:** the whole of 18.2, built last (D-61): the CI pipeline on every push and pull request, the manual API deploy workflow with hosted migrations, secrets and Cloud Run deploy, and the manual mobile build and upload workflow; FR-017, accessibility requirements (section 16), TestFlight and Google Play internal testing builds, NFR verification.
- **Depends on:** M7.
- **Definition of done:** CI is green and blocks merging on failure; the API deploys to Cloud Run and migrations apply to an empty Supabase project; the app is installable by friends through internal testing channels; all NFRs verified.

# Appendix

## 20. Decisions Log
| # | Decision | Alternatives considered | Rationale |
|---|----------|-------------------------|-----------|
| D-1 | Scale: the author and friends | Narrow public; wide public | User choice |
| D-2 | No revenue; author pays | Donations; paid AI limits; ads | User choice |
| D-3 | Variable cost budget 50 PLN per month | 200, 500 PLN | User choice |
| D-4 | Supabase Free plan | Pro 25 USD; Free then Pro | User choice (overrides the 25 USD Pro cost in the source brief) |
| D-5 | Internal testing distribution | APK; public stores | User choice |
| D-6 | Android and iOS | — | User choice |
| D-7 | Single role, no admin | User + admin | User choice |
| D-8 | Manual daily goals | Calculator; both | User choice |
| D-9 | Success measured by scan speed (≤ 10 s) and regularity (≥ 5/7 days) | One of the two | User choice |
| D-10 | AI included as demo with 1 per user per day | Out of scope; "coming soon" button | User choice (overrides source brief's AI scope as a full feature) (deferred to post-MVP, see D-59) |
| D-11 | OCR moved to post-MVP | OCR in MVP | User choice |
| D-12 | Fixed meal categories | Single list; custom | User choice |
| D-13 | Day starts 00:00 local | Configurable hour | User choice |
| D-14 | Own products private by default with sharing toggle | Always private; always shared | User choice |
| D-15 | Units g, ml, serving | g only; g and serving | User choice |
| D-16 | Past and future days editable without limit | Only back; only today | User choice |
| D-17 | Free Supabase plan, no deadline, only AI agent implements | — | User choice |
| D-18 | Data collected: email and diary | Body data; anonymous | User choice |
| D-19 | Extra MVP features: weekly summary, offline, copy meal, reminders | — | User choice |
| D-20 | Email + password, Google, Apple | Email only; magic link | User choice |
| D-21 | Polish and English | Polish only | User choice |
| D-22 | Flutter | React Native + TypeScript | User choice |
| D-23 | Supabase + Go REST API (whole API), Go hosted on Cloud Run | Edge Functions; NestJS; Fly.io; Railway | User choice (overrides Edge Functions from the source brief) |
| D-24 | OpenAI GPT-4o mini | Claude Haiku 5.5; Gemini Flash | User choice (deferred to post-MVP, see D-59) |
| D-25 | Go uses Supabase JWT + direct SQL | Supabase REST with RLS | User choice |
| D-26 | Offline conflicts: last write wins | Append-only | User choice |
| D-27 | REST + OpenAPI | gRPC | User choice |
| D-28 | Local notifications | Server push | User choice |
| D-29 | Drift (SQLite) | Isar/Hive | User choice |
| D-30 | GitHub Actions with unit tests | Plus integration tests | User choice |
| D-31 | Barcode lookup p95 ≤ 4 s | ≤ 2 s | User choice |
| D-32 | Light/dark by system | Light only; manual | User choice |
| D-33 | Account deletion in app | Via admin | User choice |
| D-34 | AI returns ingredients with weights, editable | Single entry; DB matching | User choice (deferred to post-MVP, see D-59) |
| D-35 | Up to 3 reminders per day | One; per meal | User choice |
| D-36 | Weekly summary: kcal vs goal, last 7 days | Calendar week; with macros | User choice |
| D-37 | Recents: 20 | 50 | User choice |
| D-38 | Monorepo | Two repos | User choice |
| D-39 | Product name Lean Tracker | — | User input |
| D-40 | Markdown, English PRD | — | User choice |
| D-41 | Password minimum 8 characters | 12 | User choice |
| D-42 | Favorites available offline | Online only | User choice |
| D-43 | Firebase Analytics with opt-in | Own events table; opt-out | User choice (deferred to post-MVP, see D-59) |
| D-44 | Android 10+, iOS 16+ | Android 8+, iOS 15+ | User choice |
| D-45 | Global AI block at 1000 calls per month, counted by calls | Token-based estimate | User choice (deferred to post-MVP, see D-59) |
| D-46 | Basic accessibility | None | User choice |
| D-47 | Validation ranges: quantity 0.1–10000, kcal goal 500–10000 | Narrower ranges | User choice |
| D-48 | AI limit day and month in Europe/Warsaw | UTC; device time zone | User choice (deferred to post-MVP, see D-59) |
| D-49 | Open Food Facts is not stored server-side; products are copied into entry snapshots | Server cache | Implementation detail derived from D-26 and offline requirement; not confirmed separately |
| D-50 | Future desktop application is a web application (browser), planned post-MVP; the user declined changes to the AI model and distribution for now | Native desktop (Windows/macOS/Linux) | User choice |
| D-51 | Monorepo with Clean Architecture, module-per-capability, strict application and module boundaries | Layered without strict boundaries | User requirement; the concrete layer names, module list and directory names are derived from it and not confirmed separately |
| D-52 | One environment (`test`); no production in the MVP | Test + production | User choice |
| D-53 | API deploy is a manual GitHub Actions workflow | Automatic on merge to main | User choice |
| D-54 | Migrations are applied in the pipeline before the API deploy | Manual Supabase CLI | User choice |
| D-55 | Secrets in GitHub Secrets, injected as Cloud Run environment variables | GCP Secret Manager | User choice |
| D-56 | GitHub Actions authenticates to Google Cloud with a service account key | Workload Identity Federation | User choice |
| D-57 | Mobile builds and uploads through a GitHub Actions workflow | Manual local builds | User choice |
| D-58 | Container registry, rollback by image tag, forward-only migrations and the secret names in 18.2 | Other registries | Derived from D-53–D-57; not confirmed separately |
| D-59 | AI meal-photo recognition and Firebase Analytics are removed from the MVP and recorded as future scope (section 23) | Keep in MVP | User choice; decisions D-10, D-24, D-34, D-43, D-45, D-48 and the KPI measurement method are deferred with them |
| D-60 | UI follows `docs/DESIGN.html` (14 boards, light and dark palettes, Nunito) on top of Material 3 components | Plain Material 3 with a seed color | User choice; the design file was added after PRD v1.0. Bundling the Nunito font as an app asset and mapping the tokens to the Flutter `ColorScheme` are derived, not confirmed separately |
| D-61 | CI, deployment, hosted migrations and secrets (18.2) are built last, in M8; M1–M7 run and are tested locally only | CI and deploy in M1 | User choice; everything works locally first, so nothing earlier needs the pipeline |

## 21. Open Questions
None.

## 22. Glossary
| Term | Definition |
|------|------------|
| kcal | Kilocalories, energy unit |
| Macros | Protein, fat and carbohydrates in grams |
| OFF | Open Food Facts, open product database with barcode lookup |
| Entry | One diary record of a product with quantity, unit, meal and date |
| Snapshot | Copy of product name and values stored in an entry |
| Serving | Unit defined by a product's `serving_size` |
| OCR | Text recognition of nutrition tables (post-MVP) |

## 23. Future Scope (post-MVP, not implemented in the MVP)
This section keeps the specification of features deferred by the user. Nothing in it must be built in the MVP. Identifiers are kept so that the specification can be restored without renumbering. When these features return, the architecture must follow 18.1 (module `ai` and module `analytics`), the secrets `OPENAI_API_KEY`, `AI_DAILY_LIMIT_PER_USER`, `AI_MONTHLY_LIMIT_GLOBAL` must be added to 18.2, the model `ai_usage` must be added to section 13, and the API route `POST /v1/ai/recognize` must be added to the OpenAPI contract.

### 23.1 AI meal-photo recognition (demo)
- **Context:** OpenAI GPT-4o mini (vision) called from the Go API; budget cap 50 PLN per month; Europe/Warsaw day and month boundaries; the add-entry screen gets an AI button; source value `ai` is added to `diary_entries.source`.
- **Integration:** OpenAI API (GPT-4o mini, vision): JPEG ≤ 1 MB → ingredient list; timeout 20 s → `AI_PROVIDER_ERROR`; no limit consumed.
- **Access:** AI recognition 1/day per user, subject to the global limit.
- **KPI:** AI monthly cost ≤ 50 PLN each calendar month, measured on the OpenAI usage dashboard and enforced by BR-011.
- **Risk R-AI-1:** AI cost exceeds 50 PLN per month; mitigation: BR-011 (1 per user per day, global monthly limit 1000 with automatic block) and BR-013 (photo resize).

### BR-011: AI demo limits
- **Rule:** The system must allow at most 1 successful AI recognition per user per calendar day in time zone Europe/Warsaw. The system must allow at most 1000 AI recognitions per calendar month in time zone Europe/Warsaw across all users. After the monthly limit is reached, the system must reject all AI requests until the first day of the next month with error `AI_MONTHLY_LIMIT`. Failed calls (provider error, invalid image) must not consume the user's daily limit. The limits must be configurable through environment variables `AI_DAILY_LIMIT_PER_USER` (default 1) and `AI_MONTHLY_LIMIT_GLOBAL` (default 1000).
- **Applies to:** AI recognition.
- **Exceptions:** None.

### BR-012: AI result is a proposal
- **Rule:** The system must return AI results as an editable proposal: a list of ingredients, each with name, estimated weight in grams and kcal, protein, fat, carbohydrates per 100 g. The system must save diary entries only after the user confirms the proposal. The user must be able to edit name, weight and values and remove ingredients before confirming.
- **Applies to:** AI recognition.
- **Exceptions:** None.

### BR-013: Photo handling
- **Rule:** The app must resize the photo to a maximum of 1024 px on the longer side and encode it as JPEG before sending it to the API. The system must not store the photo after the recognition request finishes.
- **Applies to:** AI recognition.
- **Exceptions:** None.


### BP-005: AI meal recognition (demo)
1. User taps AI button and takes or selects a photo.
2. App resizes the photo (BR-013) and sends it to the API.
3. API checks daily and monthly limits (BR-011).
4. API calls OpenAI GPT-4o mini and returns a proposal.
5. User edits and confirms (BR-012); app saves entries.
- **Statuses & allowed transitions:** request status `success` or `failed`; a request counts toward the limits only in `success`.
- **Exceptions:** daily limit reached → `AI_DAILY_LIMIT`; monthly limit reached → `AI_MONTHLY_LIMIT`; provider error → `AI_PROVIDER_ERROR`; offline → button disabled with message.
- **Related rules:** BR-011, BR-012, BR-013.


### UF-007: AI recognition
1. User taps AI; app opens camera/gallery picker.
2. App shows loading state, then proposal list with editable name, weight, values per 100 g.
3. User taps Confirm, chooses meal category and date; app saves entries.
- **Error states:** daily limit → "Daily AI limit reached. Try again tomorrow."; monthly limit → "AI is unavailable until next month."; provider error → "Recognition failed. Try again."; offline → button disabled.
- **Empty states:** AI returns no ingredients → "No food recognized."

### FR-014: AI recognition (demo)
- **Implements:** BP-005, BR-011, BR-012, BR-013, R-1
- **Description:** The API endpoint `POST /v1/ai/recognize` must accept a JPEG image up to 1 MB, check limits, call OpenAI GPT-4o mini and return a JSON list of ingredients (name, weight_g, kcal_per_100, protein_per_100, fat_per_100, carbs_per_100). The OpenAI API key must exist only in the Go service environment.
- **Inputs / validation:** `Content-Type: image/jpeg`, size ≤ 1 MB.
- **Edge cases:** provider timeout after 20 s returns `AI_PROVIDER_ERROR` and does not consume the limit.
- **Acceptance criteria:**
  - Given a user with 0 recognitions today, when a valid photo is sent, then HTTP 200 returns a proposal and the daily counter becomes 1.
  - Given a user with 1 recognition today (Europe/Warsaw), when another request is sent, then HTTP 429 with `AI_DAILY_LIMIT` is returned.
  - Given 1000 recognitions in the month, when any user sends a request, then HTTP 429 with `AI_MONTHLY_LIMIT` is returned.
  - Given provider failure, when the request ends, then the counters are unchanged.

### FR-015: Analytics
- **Implements:** BR-018, A-1, A-2, A-3
- **Description:** The app must log Firebase Analytics events only after consent: `entry_saved` (source: scan|search|favorite|recent|ai|copy), `entry_saved_via_scan` (duration_ms from app open), `barcode_scan`, `barcode_not_found`, `ai_recognition` (status).
- **Acceptance criteria:**
  - Given consent declined, when the user saves an entry, then no event is sent.
  - Given consent accepted, when the user saves an entry from a scan, then `entry_saved_via_scan` is sent with `duration_ms`.

### ai_usage
| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| id | uuid | yes | PK, server-generated | |
| user_id | uuid | yes | FK | |
| used_at | timestamptz | yes | | |
| day_warsaw | date | yes | | date in Europe/Warsaw |
| month_warsaw | text | yes | `YYYY-MM` | |
- **Relations:** only `success` calls are stored.
- **Retention / deletion:** deleted with the account; rows older than 13 months must be deleted by a scheduled job.


### 23.2 Firebase Analytics (opt-in)
- **Context:** Firebase Analytics SDK in the Flutter app; opt-in consent screen on first launch; consent toggle in Settings; used to measure assumptions A-1, A-2, A-3 and the KPIs in section 8 (events `barcode_scan`, `barcode_not_found`, `entry_saved`, `entry_saved_via_scan`).
- **Integration:** Firebase Analytics, events from FR-015, silent failure.
- **Privacy:** the app must not send data to Firebase before consent.
- **Verification:** a test that analytics are disabled before consent.

### BR-018: Analytics consent
- **Rule:** The app must not send any data to Firebase Analytics before the user gives opt-in consent on first launch. The user must be able to change consent in settings at any time. Analytics events must not contain email, product names or entry contents.
- **Applies to:** App.
- **Exceptions:** None.


### NFR-005 and NFR-006 (deferred)
### NFR-005: Privacy
- **Requirement:** The app must not send data to Firebase before consent. Photos must not be persisted on the server.
- **Verification:** Test that analytics are disabled before consent; code review of the AI handler.

### NFR-006: Cost
- **Requirement:** OpenAI cost must not exceed 50 PLN per calendar month; enforced by BR-011.
- **Verification:** Unit test of limit logic; monthly review of the OpenAI dashboard.


### M-AI (deferred): AI demo
- **Includes:** FR-014, UF-007, BP-005, limits and `ai_usage`.
- **Depends on:** M6.
- **Definition of done:** acceptance criteria of FR-014 pass, including daily and monthly limit tests.

