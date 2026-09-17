#!/usr/bin/env node
/**
 * Seeds the two fixed accounts from env vars. Safe to re-run — upserts by
 * username instead of failing on a duplicate.
 */
import bcrypt from 'bcryptjs';
import { env } from '../config/env.js';
import { pool, closePool } from './pool.js';

function required(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var for seeding: ${name}`);
  return value;
}

async function upsertUser({ username, displayName, pin }) {
  const pinHash = await bcrypt.hash(pin, 10);
  await pool.query(
    `INSERT INTO users (username, display_name, pin_hash)
     VALUES ($1, $2, $3)
     ON CONFLICT (username)
     DO UPDATE SET display_name = EXCLUDED.display_name, pin_hash = EXCLUDED.pin_hash`,
    [username, displayName, pinHash],
  );
  console.log(`  seeded  ${username}`);
}

async function seed() {
  console.log(`Seeding users (${env.nodeEnv}) ...`);
  await upsertUser({
    username: required('SEED_USER1_USERNAME').toLowerCase(),
    displayName: required('SEED_USER1_NAME'),
    pin: required('SEED_USER1_PIN'),
  });
  await upsertUser({
    username: required('SEED_USER2_USERNAME').toLowerCase(),
    displayName: required('SEED_USER2_NAME'),
    pin: required('SEED_USER2_PIN'),
  });
  console.log('Done.');
}

try {
  await seed();
} catch (err) {
  console.error(`\nSeed error: ${err.message}`);
  process.exitCode = 1;
} finally {
  await closePool();
}
