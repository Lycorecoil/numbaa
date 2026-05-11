import { connectDatabase } from './config/database';
import { connectRedis } from './config/redis';
import { env } from './config/env';
import { initBaileysClient } from './whatsapp/baileys.client';
import app from './app';

const start = async (): Promise<void> => {
  await connectDatabase();
  await connectRedis();
  if (!env.BYPASS_WHATSAPP) await initBaileysClient();
  app.listen(env.PORT, () => {
    console.log(`\n NUMBAA Backend sur le port ${env.PORT} [${env.NODE_ENV}]\n`);
  });
};

start().catch((err) => {
  console.error('Echec du demarrage:', err);
  process.exit(1);
});
