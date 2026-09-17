# Personal Reminder App — V1 Design

Private Android reminder app for two people (owner + spouse), each on their
own phone, with reminders synced through a small cloud backend. Not published
to the Play Store — installed as an APK on both devices.

## Core concept

Three fixed categories only: 💼 Business, 👤 Self, 🙏 Seva. No others in V1.
Primary flow: **open app → tap category → title + time → save**, in as few
taps as possible.

## Screens

1. **Home** — greeting, date, three category cards (with today's count each),
   "Next Up" card, daily spiritual line, upcoming preview.
2. **Category List** (one screen, parameterized by category) — Today /
   Upcoming / Completed sections.
3. **Add/Edit Reminder** — bottom sheet. Minimal by default (title, date,
   time); "More options" expands to description, priority, sound, vibration,
   alarm mode, notification style, snooze duration, repeat, end date.
4. **Alarm Wake Screen** — full-screen Flutter route, reached only via a
   firing alarm-style reminder's full-screen intent.
5. **Settings** — General (name, theme, language) / Notifications (default
   sound, vibration, snooze) / Reminders (default behavior) / Advanced
   (permission status, battery optimization, backup/export).

No separate reminder-detail screen — tapping a list item opens the Edit
sheet directly.

## Reminder types & recurrence

Two types sharing one data model: `normal` and `alarm`. `repeatRule`: none /
daily / weekly-with-days / custom-interval. Recurring reminders are a single
template row plus a `reminder_completions` log per fired occurrence (enables
history/streaks later without a schema change).

## Design system

Material 3, restyled to feel premium rather than stock-Android: 24dp rounded
cards, soft shadows over hard borders, generous spacing. Full light + dark
themes from day one. Per-category accent colors, centralized in one
`AppColors` definition:

- **Business** → deep indigo/blue (`#3D5AFE` family)
- **Self** → violet-teal blend (`#7C4DFF` / `#26A69A`)
- **Seva** → warm saffron/amber (`#FF8F00` family)

Micro-interactions only where they aid usability: card press scale+ripple,
completion checkmark animation, spring bottom-sheet transitions.

## Local scheduling architecture (unchanged by cloud sync)

The device is the source of truth for *when an alarm fires* — this must keep
working fully offline, on a locked screen, after a reboot, regardless of
cloud connectivity.

- **Normal reminders**: `flutter_local_notifications` — 6 notification
  channels (`{business,self,seva} × {normal,alarm}`), scheduled locally,
  Done/Snooze notification actions handled in a background isolate that
  writes straight to the local Drift DB.
- **Alarm-style reminders**: a native Kotlin module invoked via
  `MethodChannel`:
  - `AlarmManager.setExactAndAllowWhileIdle(...)` to schedule
  - `BroadcastReceiver` fires at trigger time, posts a full-screen-intent
    notification
  - Full-screen intent launches a **Flutter route** (Wake Screen) so it
    matches the app's design system rather than being a bespoke native UI
  - `BootReceiver` (`RECEIVE_BOOT_COMPLETED`) re-reads pending alarm-style
    reminders from Drift and re-schedules them after every device restart
- No persistent foreground service. No FCM/Firebase — push is not required
  because scheduling is local; cloud sync (below) is pull-based.

## Cloud backend & sync (part of V1)

Reference implementation: `C:\369dc` (Node + Express + PostgreSQL API on
Render, Neon-hosted Postgres, JWT auth) — same account, same proven pattern,
**separate repo and separate Neon database** (no data or table sharing with
369dc).

- **Backend**: Node.js + Express, deployed on Render as its own web service.
- **Database**: a new Neon Postgres project (free, no-expiry tier — not
  Render's own Postgres, which expires after 30 days on the free plan).
- **Auth**: two fixed accounts (owner + spouse), username + PIN login, JWT
  issued on login, stored on-device via `flutter_secure_storage`. No public
  sign-up, no OAuth — mirrors 369dc's owner/staff model.
- **Sync strategy**: pull-on-resume + periodic background pull, last-write-
  wins via `updated_at`.
  - App pulls latest reminders from the API on every foreground/resume and
    pushes local pending changes.
  - A WorkManager job syncs every ~15–30 minutes in the background so alarms
    stay current even when the app isn't open.
  - Conflict resolution: newer `updated_at` wins — sufficient for a
    2-person household; no CRDT/real-time infra needed.
  - No push notifications required for sync; local `AlarmManager` firing is
    entirely independent of connectivity.
- Client architecture keeps a clean `ReminderRepository` interface; the sync
  layer sits behind it alongside the local Drift source, so this was
  designed to be addable without touching UI/domain code either way.

## Data model

**Local (Drift, on-device) and remote (Postgres) schemas mirror each other:**

```
reminders(id, owner_user_id, title, description, category, type,
          scheduled_at, repeat_rule, repeat_days, end_date, priority,
          sound_id, vibration_enabled, snooze_minutes, is_completed,
          completed_at, created_at, updated_at, deleted_at)

reminder_completions(id, reminder_id, occurrence_date, completed_at, status)

spiritual_lines(id, text_en, text_gu, sort_order, is_active)

app_settings(key, value)   -- per-device: name, theme_mode, language,
                              default_sound, default_vibration,
                              default_snooze_minutes
```

**Remote-only:**

```
users(id, username, pin_hash, display_name, created_at)
```

`deleted_at` is a soft-delete marker so sync can propagate deletions between
devices without a separate tombstone table.

## Technology stack

| Layer | Choice | Why |
|---|---|---|
| Mobile framework | Flutter (stable) | Cross-cutting UI + business logic in one codebase |
| State management | Riverpod (code-gen) | Minimal boilerplate, no `BuildContext` coupling, plugs Drift `Stream` queries straight into providers |
| Local DB | Drift (SQLite) | Compile-checked SQL, reactive streams, clean migrations |
| Local notifications | `flutter_local_notifications` | Channels, scheduling, action buttons |
| Alarm scheduling | Native Kotlin (`AlarmManager`, `BroadcastReceiver`, `BootReceiver`) | Reliability Flutter-only scheduling can't guarantee across reboot/Doze |
| Backend | Node.js + Express | Matches 369dc; team is already familiar with it |
| Remote DB | Postgres via Neon | Free, no-expiry, matches 369dc's proven setup |
| Hosting | Render (existing account) | Same account as 369dc; new, separate service + repo |
| Auth | JWT + PIN login | Matches 369dc's private owner/staff model; no OAuth needed for 2 known users |

## Flutter project structure

```
lib/
  core/{theme, constants, utils}
  data/{database, models, repositories}
  domain/{entities, services}
  features/{home, reminders/{business,self,seva}, spiritual, settings}
  services/{notification, alarm, scheduling, sync}
  shared/widgets
android/app/src/main/kotlin/.../{AlarmScheduler.kt, ReminderAlarmReceiver.kt, BootReceiver.kt}
```

## Backend project structure (mirrors 369dc/server)

```
server/
  src/
    server.js
    db/ (migrate.js, seed.js, schema)
    routes/ (auth, reminders, spiritual-lines, sync)
    middleware/ (auth, error handling)
  .env.example
  package.json
```

## Android requirements

`minSdkVersion 26`, `targetSdk` latest stable. Permissions:
`POST_NOTIFICATIONS` (13+), `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` (12+),
`USE_FULL_SCREEN_INTENT`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `WAKE_LOCK`.
Settings → Advanced surfaces exact-alarm permission status and a battery-
optimization exemption prompt (OEM battery managers are the most common real-
world cause of missed alarms).

## Privacy

No analytics, no ads, no third-party trackers. Data lives only in this app's
own Neon database and the two devices' local stores — never shared with or
sold to anyone else. (This app is no longer offline-only, per explicit
decision to add cloud sync in V1, but remains otherwise private/self-hosted.)

## Explicitly out of scope for V1

Real-time push (FCM), more than two accounts, shared/collaborative editing
UI beyond last-write-wins, location/usage-based triggers, AI-generated
content, voice input, home-screen widgets, statistics/habit tracking. The
architecture (clean repository boundaries, `updated_at`-based sync) allows
adding these later without a rewrite.

## Implementation roadmap

Each phase must build/compile before the next starts.

0. Repo scaffold (Flutter app + Node backend), theme, empty Home screen
1. Backend: Express skeleton, Neon connection, migrations, auth (JWT+PIN),
   health check — deployed to Render
2. Flutter: Drift schema + repositories (local CRUD, no UI)
3. Flutter: Home UI wired to real local data
4. Flutter: Add/Edit bottom sheet + Category list (Today/Upcoming/Completed)
5. Normal-reminder notifications (channels, scheduling, Done/Snooze actions)
6. Native alarm module (AlarmManager, BroadcastReceiver, BootReceiver)
7. Alarm-style reminders + Wake Screen route
8. Recurrence + completion history
9. Cloud sync: reminders API endpoints + client sync service (pull-on-resume
   + WorkManager periodic pull, last-write-wins)
10. Settings screen + permission/battery status
11. Spiritual line (seed data, daily rotation, edit)
12. Polish: animations, accessibility, dark/light refinement
13. *(stretch)* JSON export/import

## Open items pending user input

- Flutter + Android SDK installation on this machine (in progress)
- Neon Postgres project + `DATABASE_URL` for the backend (pending)
- GitHub repository to push to (pending — name/account needed)
