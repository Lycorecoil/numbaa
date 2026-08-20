import Redis from 'ioredis';
import { env } from './env';

export const redis = new Redis(env.REDIS_URL, {
  maxRetriesPerRequest: 3,
  // Toujours retenter la reconnexion (jamais `null`) : sur Vercel, un conteneur
  // "warm" peut réutiliser ce client des heures après que le provider Redis a
  // fermé la connexion TCP inactive. Si retryStrategy renvoie `null`, ioredis
  // passe en statut 'end' définitif et toute commande suivante échoue avec
  // "Connection is closed." jusqu'au prochain cold start.
  retryStrategy: (times) => Math.min(times * 200, 2000),
  tls: env.REDIS_URL.startsWith('rediss://') ? { rejectUnauthorized: false } : undefined,
});

redis.on('error', (err) => console.error('[Redis] Error:', err.message));

export async function connectRedis(): Promise<void> {
  await redis.ping();
}
