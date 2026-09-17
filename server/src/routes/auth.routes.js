import { randomUUID } from 'node:crypto';
import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { query } from '../db/pool.js';
import { requireAuth, signToken } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { asyncHandler, unauthorized } from '../lib/errors.js';

const router = Router();

// A real hash of a value nobody knows, so a login attempt for a non-existent
// username still costs one bcrypt round and cannot be spotted by timing.
const DUMMY_HASH = bcrypt.hashSync(randomUUID(), 10);

const loginSchema = z.object({
  username: z.string().trim().toLowerCase().min(3).max(32),
  pin: z.string().min(4).max(72),
});

router.post(
  '/login',
  validate({ body: loginSchema }),
  asyncHandler(async (req, res) => {
    const { username, pin } = req.body;

    const { rows } = await query(
      `SELECT id, username, display_name, pin_hash, is_active
         FROM users
        WHERE username = $1`,
      [username],
    );
    const user = rows[0];

    // Same message either way, so a wrong username is indistinguishable from a
    // wrong PIN.
    const ok = await bcrypt.compare(pin, user?.pin_hash ?? DUMMY_HASH);

    if (!user || !ok || !user.is_active) {
      throw unauthorized('Wrong username or PIN');
    }

    await query('UPDATE users SET last_login_at = now() WHERE id = $1', [user.id]);

    res.json({
      token: signToken(user),
      user: {
        id: user.id,
        username: user.username,
        displayName: user.display_name,
      },
    });
  }),
);

/** Who am I — used by the app to restore a session on launch. */
router.get('/me', requireAuth, (req, res) => {
  res.json({ user: req.user });
});

export default router;
