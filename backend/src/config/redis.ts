import Redis from 'ioredis';
import { env } from './env';

export const redis = new Redis(env.REDIS_URL, {
  maxRetriesPerRequest: 3,
  retryStrategy: (times) => (times > 3 ? null : Math.min(times * 200, 2000)),
  tls: env.REDIS_URL.startsWith('rediss://') ? { rejectUnauthorized: false } : undefined,
});

redis.on('error', (err) => console.error('[Redis] Error:', err.message));

export async function connectRedis(): Promise<void> {
  await redis.ping();
}
