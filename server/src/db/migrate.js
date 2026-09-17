#!/usr/bin/env node
/**
 * Minimal forward-only migration runner.
 *
 *   npm run migrate           apply every pending migration
 *   npm run migrate:status    list applied / pending, no changes
 *   node src/db/migrate.js --reset --yes    drop and rebuild the whole schema
 *
 * Migrations are the .sql files in ./migrations, applied in filename order.
 * Each runs in its own transaction and is recorded in schema_migrations with a
 * checksum, so editing an already-applied file is caught instead of ignored.
 */
import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { env } from '../config/env.js';
import { pool, closePool } from './pool.js';

const MIGRATIONS_DIR = join(dirname(fileURLToPath(import.meta.url)), 'migrations');

const TRACKING_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS schema_migrations (
    filename    text        PRIMARY KEY,
    checksum    text        NOT NULL,
    applied_at  timestamptz NOT NULL DEFAULT now()
  )
`;

function checksum(contents) {
  return createHash('sha256').update(contents).digest('hex').slice(0, 16);
}

async function loadMigrations() {
  const files = (await readdir(MIGRATIONS_DIR))
    .filter((f) => f.endsWith('.sql'))
    .sort();

  return Promise.all(
    files.map(async (filename) => {
      const sql = await readFile(join(MIGRATIONS_DIR, filename), 'utf8');
      return { filename, sql, checksum: checksum(sql) };
    }),
  );
}

async function appliedMigrations() {
  await pool.query(TRACKING_TABLE_SQL);
  const { rows } = await pool.query(
    'SELECT filename, checksum, applied_at FROM schema_migrations ORDER BY filename',
  );
  return new Map(rows.map((r) => [r.filename, r]));
}

async function status() {
  const [migrations, applied] = await Promise.all([loadMigrations(), appliedMigrations()]);

  if (migrations.length === 0) {
    console.log('No migration files found in', MIGRATIONS_DIR);
    return;
  }

  console.log(`Migrations in ${MIGRATIONS_DIR}\n`);
  for (const m of migrations) {
    const record = applied.get(m.filename);
    if (!record) {
      console.log(`  pending   ${m.filename}`);
    } else if (record.checksum !== m.checksum) {
      console.log(`  CHANGED   ${m.filename}  (applied ${record.applied_at.toISOString()})`);
    } else {
      console.log(`  applied   ${m.filename}  (${record.applied_at.toISOString()})`);
    }
  }

  const orphans = [...applied.keys()].filter(
    (name) => !migrations.some((m) => m.filename === name),
  );
  for (const name of orphans) {
    console.log(`  MISSING   ${name}  (recorded as applied but the file is gone)`);
  }
}

async function migrate() {
  const [migrations, applied] = await Promise.all([loadMigrations(), appliedMigrations()]);

  for (const m of migrations) {
    const record = applied.get(m.filename);
    if (record) {
      if (record.checksum !== m.checksum) {
        throw new Error(
          `${m.filename} was already applied but its contents changed. ` +
            'Never edit an applied migration — add a new numbered file instead.',
        );
      }
      continue;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(m.sql);
      await client.query(
        'INSERT INTO schema_migrations (filename, checksum) VALUES ($1, $2)',
        [m.filename, m.checksum],
      );
      await client.query('COMMIT');
      console.log(`applied  ${m.filename}`);
    } catch (err) {
      await client.query('ROLLBACK').catch(() => {});
      throw new Error(`${m.filename} failed: ${err.message}`);
    } finally {
      client.release();
    }
  }

  const pending = migrations.filter((m) => !applied.has(m.filename)).length;
  console.log(pending === 0 ? 'Already up to date.' : `Done — ${pending} migration(s) applied.`);
}

async function reset() {
  if (env.isProduction) {
    throw new Error('Refusing to reset the schema with NODE_ENV=production');
  }
  if (!process.argv.includes('--yes')) {
    throw new Error('--reset drops every table. Re-run with --reset --yes to confirm.');
  }
  console.log('Dropping schema public ...');
  await pool.query('DROP SCHEMA public CASCADE');
  await pool.query('CREATE SCHEMA public');
  await migrate();
}

const command = process.argv.includes('--status')
  ? status
  : process.argv.includes('--reset')
    ? reset
    : migrate;

try {
  await command();
} catch (err) {
  console.error(`\nMigration error: ${err.message}`);
  process.exitCode = 1;
} finally {
  await closePool();
}
