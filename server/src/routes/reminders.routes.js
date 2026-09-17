import { Router } from 'express';
import { z } from 'zod';
import { pool, query } from '../db/pool.js';
import { requireAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { asyncHandler } from '../lib/errors.js';

const router = Router();
router.use(requireAuth);

const CATEGORIES = ['business', 'self', 'seva'];
const TYPES = ['normal', 'alarm'];
const REPEAT_RULES = ['none', 'daily', 'weekly', 'custom'];
const PRIORITIES = ['low', 'normal', 'high'];

const reminderSchema = z.object({
  id: z.string().uuid(),
  title: z.string().trim().min(1).max(200),
  description: z.string().trim().max(2000).nullable().optional(),
  category: z.enum(CATEGORIES),
  type: z.enum(TYPES).default('normal'),
  scheduledAt: z.string().datetime({ offset: true }),
  repeatRule: z.enum(REPEAT_RULES).default('none'),
  repeatDays: z.array(z.number().int().min(1).max(7)).nullable().optional(),
  endDate: z.string().date().nullable().optional(),
  priority: z.enum(PRIORITIES).default('normal'),
  soundId: z.string().max(100).nullable().optional(),
  vibrationEnabled: z.boolean().default(true),
  snoozeMinutes: z.number().int().min(1).max(60).default(5),
  isCompleted: z.boolean().default(false),
  completedAt: z.string().datetime({ offset: true }).nullable().optional(),
  createdAt: z.string().datetime({ offset: true }),
  updatedAt: z.string().datetime({ offset: true }),
  deletedAt: z.string().datetime({ offset: true }).nullable().optional(),
});

const syncSchema = z.object({
  since: z.string().datetime({ offset: true }).nullable().optional(),
  changes: z.array(reminderSchema).max(500).default([]),
});

function toDto(row) {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    category: row.category,
    type: row.type,
    scheduledAt: row.scheduled_at,
    repeatRule: row.repeat_rule,
    repeatDays: row.repeat_days,
    endDate: row.end_date,
    priority: row.priority,
    soundId: row.sound_id,
    vibrationEnabled: row.vibration_enabled,
    snoozeMinutes: row.snooze_minutes,
    isCompleted: row.is_completed,
    completedAt: row.completed_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    deletedAt: row.deleted_at,
  };
}

/** Plain list of this account's non-deleted reminders — mainly for manual testing. */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const { rows } = await query(
      `SELECT * FROM reminders WHERE owner_user_id = $1 AND deleted_at IS NULL ORDER BY scheduled_at`,
      [req.user.id],
    );
    res.json({ reminders: rows.map(toDto) });
  }),
);

/**
 * Two-way sync in one round trip:
 *  1. Upsert every incoming change, last-write-wins on `updated_at`.
 *  2. Return every reminder (including soft-deleted ones, so the client can
 *     remove them locally) touched since `since`.
 */
router.post(
  '/sync',
  validate({ body: syncSchema }),
  asyncHandler(async (req, res) => {
    const { since, changes } = req.body;
    const ownerUserId = req.user.id;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      for (const r of changes) {
        await client.query(
          `INSERT INTO reminders (
             id, owner_user_id, title, description, category, type,
             scheduled_at, repeat_rule, repeat_days, end_date, priority,
             sound_id, vibration_enabled, snooze_minutes, is_completed,
             completed_at, created_at, updated_at, deleted_at
           ) VALUES (
             $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
             $16, $17, $18, $19
           )
           ON CONFLICT (id) DO UPDATE SET
             title = EXCLUDED.title,
             description = EXCLUDED.description,
             category = EXCLUDED.category,
             type = EXCLUDED.type,
             scheduled_at = EXCLUDED.scheduled_at,
             repeat_rule = EXCLUDED.repeat_rule,
             repeat_days = EXCLUDED.repeat_days,
             end_date = EXCLUDED.end_date,
             priority = EXCLUDED.priority,
             sound_id = EXCLUDED.sound_id,
             vibration_enabled = EXCLUDED.vibration_enabled,
             snooze_minutes = EXCLUDED.snooze_minutes,
             is_completed = EXCLUDED.is_completed,
             completed_at = EXCLUDED.completed_at,
             updated_at = EXCLUDED.updated_at,
             deleted_at = EXCLUDED.deleted_at
           WHERE reminders.owner_user_id = EXCLUDED.owner_user_id
             AND reminders.updated_at < EXCLUDED.updated_at`,
          [
            r.id,
            ownerUserId,
            r.title,
            r.description ?? null,
            r.category,
            r.type,
            r.scheduledAt,
            r.repeatRule,
            r.repeatDays ?? null,
            r.endDate ?? null,
            r.priority,
            r.soundId ?? null,
            r.vibrationEnabled,
            r.snoozeMinutes,
            r.isCompleted,
            r.completedAt ?? null,
            r.createdAt,
            r.updatedAt,
            r.deletedAt ?? null,
          ],
        );
      }

      const serverTime = (await client.query('SELECT now() AS now')).rows[0].now;

      const { rows } = await client.query(
        since
          ? `SELECT * FROM reminders WHERE owner_user_id = $1 AND updated_at > $2 ORDER BY updated_at`
          : `SELECT * FROM reminders WHERE owner_user_id = $1 ORDER BY updated_at`,
        since ? [ownerUserId, since] : [ownerUserId],
      );

      await client.query('COMMIT');
      res.json({ serverTime, reminders: rows.map(toDto) });
    } catch (err) {
      await client.query('ROLLBACK').catch(() => {});
      throw err;
    } finally {
      client.release();
    }
  }),
);

export default router;
