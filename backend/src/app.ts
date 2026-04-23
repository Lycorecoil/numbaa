import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import path from 'path';
import { connectDatabase } from './config/database';
import { connectRedis } from './config/redis';
import { env } from './config/env';
import { initBaileysClient } from './whatsapp/baileys.client';
import routes from './routes';
import fs from 'fs';

const app = express();

// Créer le dossier uploads si nécessaire
if (!fs.existsSync(env.UPLOAD_DIR)) {
  fs.mkdirSync(env.UPLOAD_DIR, { recursive: true });
}

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
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

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

// Démarrage
const start = async (): Promise<void> => {
  await connectDatabase();
  await connectRedis();
  await initBaileysClient();

  app.listen(env.PORT, () => {
    console.log(`\n🚀 NUMBAA Backend démarré sur le port ${env.PORT} [${env.NODE_ENV}]\n`);
  });
};

start().catch((err) => {
  console.error('Échec du démarrage:', err);
  process.exit(1);
});

export { app };
