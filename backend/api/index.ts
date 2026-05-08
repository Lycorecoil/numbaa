import { redis } from '../src/config/redis';
import app from '../src/app';

// Connexions lazy pour serverless — se déclenchent au premier appel
let ready = false;
const ensureReady = async () => {
  if (ready) return;
  try {
    await redis.ping();
  } catch {
    await redis.connect();
  }
  ready = true;
};

export default async function handler(req: any, res: any) {
  await ensureReady();
  return app(req, res);
}
