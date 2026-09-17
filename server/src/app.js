import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';
import apiRoutes from './routes/index.js';

export function createApp() {
  const app = express();

  app.set('trust proxy', 1); // Render sits behind a proxy
  app.disable('x-powered-by');

  app.use(helmet());
  app.use(
    cors({
      origin(origin, callback) {
        // No Origin header: the Flutter app, curl, health checks. An unknown
        // browser origin gets no CORS headers rather than a thrown error.
        callback(null, !origin || env.corsOrigins.includes(origin));
      },
      credentials: false, // auth travels in the Authorization header, not cookies
    }),
  );
  app.use(express.json({ limit: '1mb' })); // sync batches can carry many reminders
  app.use(morgan(env.isProduction ? 'combined' : 'dev'));

  app.use('/api', apiRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
