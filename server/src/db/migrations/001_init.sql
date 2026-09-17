-- =============================================================================
-- 001_init.sql — reminder app sync backend, initial schema
--
-- Tables: users, reminders, reminder_completions
--
-- Two fixed accounts (no public sign-up, no roles — both users are peers).
-- Each account only ever sees its own reminders; there is no shared/combined
-- list. `deleted_at` is a soft-delete marker so a deletion made on one phone
-- can propagate to the other during sync instead of being invisible.
--
-- The migration runner wraps each file in a transaction — no BEGIN/COMMIT here.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto; -- gen_random_uuid()

CREATE TYPE reminder_category AS ENUM ('business', 'self', 'seva');
CREATE TYPE reminder_type AS ENUM ('normal', 'alarm');
CREATE TYPE reminder_repeat_rule AS ENUM ('none', 'daily', 'weekly', 'custom');
CREATE TYPE reminder_priority AS ENUM ('low', 'normal', 'high');
CREATE TYPE reminder_completion_status AS ENUM ('done', 'snoozed', 'missed');

CREATE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $fn$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$fn$;

-- -----------------------------------------------------------------------------
-- users — exactly two rows in practice (owner + spouse). Login is
-- username + bcrypt-hashed PIN.
-- -----------------------------------------------------------------------------
CREATE TABLE users (
  id            integer     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  username      text        NOT NULL UNIQUE,
  display_name  text        NOT NULL,
  pin_hash      text        NOT NULL,
  is_active     boolean     NOT NULL DEFAULT true,
  last_login_at timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT users_username_lowercase CHECK (username = lower(username)),
  CONSTRAINT users_username_format    CHECK (username ~ '^[a-z0-9_.-]{3,32}$'),
  CONSTRAINT users_display_name_set   CHECK (length(btrim(display_name)) > 0)
);

CREATE TRIGGER users_set_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- reminders — the id is client-generated (uuid) so the same identity is
-- shared between the on-device Drift row and this server row across sync.
-- -----------------------------------------------------------------------------
CREATE TABLE reminders (
  id                 uuid                  PRIMARY KEY,
  owner_user_id      integer               NOT NULL REFERENCES users (id),
  title              text                  NOT NULL,
  description        text,
  category           reminder_category     NOT NULL,
  type               reminder_type         NOT NULL DEFAULT 'normal',
  scheduled_at       timestamptz           NOT NULL,
  repeat_rule        reminder_repeat_rule  NOT NULL DEFAULT 'none',
  -- ISO weekday numbers (1=Mon .. 7=Sun), only meaningful when repeat_rule='weekly'
  repeat_days        smallint[],
  end_date           date,
  priority           reminder_priority     NOT NULL DEFAULT 'normal',
  sound_id           text,
  vibration_enabled  boolean               NOT NULL DEFAULT true,
  snooze_minutes     integer               NOT NULL DEFAULT 5,
  is_completed       boolean               NOT NULL DEFAULT false,
  completed_at       timestamptz,
  created_at         timestamptz           NOT NULL DEFAULT now(),
  updated_at         timestamptz           NOT NULL DEFAULT now(),
  deleted_at         timestamptz,

  CONSTRAINT reminders_title_set     CHECK (length(btrim(title)) > 0),
  CONSTRAINT reminders_snooze_range  CHECK (snooze_minutes BETWEEN 1 AND 60)
);

CREATE INDEX reminders_owner_updated_idx ON reminders (owner_user_id, updated_at);
CREATE INDEX reminders_owner_category_idx ON reminders (owner_user_id, category) WHERE deleted_at IS NULL;

-- No set_updated_at trigger here, deliberately: `updated_at` is the client's
-- edit timestamp, not the server's receive time. Sync's last-write-wins
-- conflict resolution depends on the device's own clock reaching this column
-- unmodified — a trigger that stamped `now()` on every write would make the
-- server always "win" regardless of which edit was actually newer.

-- -----------------------------------------------------------------------------
-- reminder_completions — one row per fired occurrence of a (possibly
-- recurring) reminder. Re-marking the same occurrence upserts rather than
-- duplicating, which is what makes history/streaks possible later.
-- -----------------------------------------------------------------------------
CREATE TABLE reminder_completions (
  id              integer                      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  reminder_id     uuid                         NOT NULL REFERENCES reminders (id) ON DELETE CASCADE,
  occurrence_date date                         NOT NULL,
  completed_at    timestamptz,
  status          reminder_completion_status   NOT NULL,
  created_at      timestamptz                  NOT NULL DEFAULT now(),

  CONSTRAINT reminder_completions_unique_occurrence UNIQUE (reminder_id, occurrence_date)
);
