import { env } from '../config/env.js';
import { HttpError, notFound } from '../lib/errors.js';

/**
 * Turns Postgres constraint violations into messages worth showing.
 * Returns null when the error is not one we recognise.
 * Codes: https://www.postgresql.org/docs/current/errcodes-appendix.html
 */
function translatePgError(err) {
  switch (err?.code) {
    case '23505': // unique_violation
      if (err.constraint === 'users_username_key') {
        return new HttpError(409, 'That username is taken');
      }
      if (err.constraint === 'reminder_completions_unique_occurrence') {
        return new HttpError(409, 'That occurrence is already recorded');
      }
      return new HttpError(409, 'That already exists');

    case '23503': // foreign_key_violation
      return new HttpError(409, 'That record is still referenced by something else');

    case '23502': // not_null_violation
      return new HttpError(400, `${err.column} is required`);

    case '23514': // check_violation
      return new HttpError(400, `The database rejected that value (${err.constraint})`);

    case '22P02': // invalid_text_representation — usually a bad enum/uuid value
      return new HttpError(400, 'One of the values is not a recognised option');

    case 'ECONNREFUSED':
    case '57P03': // cannot_connect_now
      return new HttpError(503, 'Database is unavailable — try again in a moment');

    default:
      return null;
  }
}

export function notFoundHandler(req, _res, next) {
  next(notFound(`No route for ${req.method} ${req.originalUrl}`));
}

export function errorHandler(err, _req, res, _next) {
  const error = err instanceof HttpError ? err : (translatePgError(err) ?? err);

  if (error instanceof HttpError) {
    if (error.status >= 500) console.error('[error]', err);
    return res.status(error.status).json({
      error: error.message,
      ...(error.details ? { details: error.details } : {}),
    });
  }

  console.error('[error]', err);
  res.status(500).json({
    error: 'Something went wrong on the server',
    ...(env.isProduction ? {} : { detail: err?.message }),
  });
}
