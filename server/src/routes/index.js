import { Router } from 'express';
import { checkConnection } from '../db/pool.js';
import { asyncHandler } from '../lib/errors.js';
import authRoutes from './auth.routes.js';
import reminderRoutes from './reminders.routes.js';

const router = Router();

/** Liveness + DB check. Render's health check points here. */
router.get(
  '/health',
  asyncHandler(async (_req, res) => {
    const now = await checkConnection();
    res.json({ ok: true, db: 'up', time: now });
  }),
);

router.use('/auth', authRoutes);
router.use('/reminders', reminderRoutes);

export default router;
