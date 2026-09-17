import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { query } from '../db/pool.js';
import { unauthorized } from '../lib/errors.js';

export function signToken(user) {
  return jwt.sign({ sub: user.id, username: user.username }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn,
  });
}

function bearerToken(req) {
  const header = req.get('authorization') ?? '';
  const [scheme, token] = header.split(' ');
  return scheme?.toLowerCase() === 'bearer' && token ? token : null;
}

/**
 * Verifies the JWT and re-reads the user row, so deactivating an account
 * takes effect immediately instead of when their token expires.
 */
export async function requireAuth(req, _res, next) {
  try {
    const token = bearerToken(req);
    if (!token) throw unauthorized();

    let payload;
    try {
      payload = jwt.verify(token, env.jwtSecret);
    } catch {
      throw unauthorized('Session expired — sign in again');
    }

    const { rows } = await query(
      'SELECT id, username, display_name, is_active FROM users WHERE id = $1',
      [payload.sub],
    );
    const user = rows[0];
    if (!user || !user.is_active) throw unauthorized('Account is no longer active');

    req.user = {
      id: user.id,
      username: user.username,
      displayName: user.display_name,
    };
    next();
  } catch (err) {
    next(err);
  }
}
