import { redis } from '../config/redis';
import { sendWhatsAppMessage } from './baileys.client';

const OTP_TTL = 300; // 5 minutes
const MAX_ATTEMPTS = 3;

function generateCode(): string {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

function otpKey(phone: string): string {
  return `otp:${phone}`;
}

export async function generateAndSendOtp(phone: string): Promise<void> {
  const key = otpKey(phone);

  // Empêcher le renvoi trop rapide (TTL > 240s = moins de 60s écoulées)
  const ttl = await redis.ttl(key);
  if (ttl > OTP_TTL - 60) {
    throw Object.assign(
      new Error('Un code a déjà été envoyé. Attends 1 minute avant de réessayer.'),
      { status: 429 }
    );
  }

  const code = generateCode();
  await redis.set(key, JSON.stringify({ code, attempts: 0 }), 'EX', OTP_TTL);

  await sendWhatsAppMessage(
    phone,
    `🔐 Votre code NUMBAA : *${code}*\n\nValable 5 minutes. Ne le partagez jamais.`
  );
}

export async function verifyOtp(phone: string, inputCode: string): Promise<void> {
  const key = otpKey(phone);
  const raw = await redis.get(key);

  if (!raw) {
    throw Object.assign(new Error('Code expiré ou non demandé. Demande un nouveau code.'), { status: 400 });
  }

  const data: { code: string; attempts: number } = JSON.parse(raw);

  if (data.attempts >= MAX_ATTEMPTS) {
    await redis.del(key);
    throw Object.assign(new Error('Trop de tentatives incorrectes. Demande un nouveau code.'), { status: 429 });
  }

  if (data.code !== inputCode) {
    data.attempts += 1;
    const ttl = await redis.ttl(key);
    await redis.set(key, JSON.stringify(data), 'EX', ttl > 0 ? ttl : 1);
    throw Object.assign(new Error('Code incorrect.'), { status: 400 });
  }

  // Code valide — consommer
  await redis.del(key);
}
