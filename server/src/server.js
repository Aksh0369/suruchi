import { createApp } from './app.js';
import { env } from './config/env.js';
import { checkConnection, closePool } from './db/pool.js';

const app = createApp();

try {
  await checkConnection();
  console.log('[db] connected');
} catch (err) {
  console.error(`[db] cannot connect: ${err.message}`);
  console.error('     Check DATABASE_URL (and DB_SSL=true for Neon/Render).');
  console.error('     If the tables are missing, run: npm run migrate');
  process.exit(1);
}

const server = app.listen(env.port, () => {
  console.log(`[server] reminder-app API on http://localhost:${env.port} (${env.nodeEnv})`);
});

async function shutdown(signal) {
  console.log(`\n[server] ${signal} — shutting down`);
  server.close(async () => {
    await closePool();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
