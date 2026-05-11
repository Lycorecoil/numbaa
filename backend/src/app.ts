import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import path from 'path';
import { connectDatabase } from './config/database';
import { connectRedis } from './config/redis';
import { env } from './config/env';
import routes from './routes';
import fs from 'fs';

const app = express();

// Vercel et tous les reverse proxies envoient X-Forwarded-For
app.set('trust proxy', 1);

// Créer le dossier uploads si nécessaire (ignoré en serverless)
try { if (!fs.existsSync(env.UPLOAD_DIR)) fs.mkdirSync(env.UPLOAD_DIR, { recursive: true }); } catch { /* read-only fs on serverless */ }

// Sécurité
app.use(helmet());

// CORS
app.use(cors({
  origin: env.isProduction ? env.ALLOWED_ORIGINS.split(',') : '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Rate limiting
const authLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: 3,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Trop de tentatives. Réessaie dans 10 minutes.' },
});

const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Trop de requêtes.' },
});

app.use(globalLimiter);
app.use('/v1/auth/request-otp', authLimiter);

// Logging
app.use(morgan(env.isProduction ? 'combined' : 'dev'));

// Body parsing
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Fichiers uploadés
app.use('/uploads', express.static(path.resolve(env.UPLOAD_DIR)));

// Routes API
app.use('/v1', routes);

// Health check
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', env: env.NODE_ENV, timestamp: new Date().toISOString() });
});

// 404
app.use((req: Request, res: Response) => {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} introuvable.` });
});

// Erreur globale
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
  console.error('[Error]', err);
  const status = typeof err.status === 'number' ? err.status : 500;
  const message = typeof err.message === 'string' ? err.message : 'Erreur interne.';
  res.status(status).json({
    success: false,
    message,
    ...(env.isDevelopment && { stack: err.stack }),
  });
});

export default app;
