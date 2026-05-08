import { redis } from '../config/redis';
import { sendWhatsAppMessage } from './baileys.client';

const OTP_TTL = 300; // 5 minutes
const MAX_ATTEMPTS = 3;

function generateCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
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

  if (env.BYPASS_WHATSAPP) {
    console.log(`[OTP] ${phone} → ${code}`);
    return;
  }
  await sendWhatsAppMessage(
    phone,
    `🔐 Votre code NUMBAA : *${code}*\n\nValable 5 minutes. Ne le partagez jamais.`
  );
}

// Lua script : atomic read → check attempts → increment or delete
// Returns: "expired" | "too_many" | "wrong" | "ok"
const verifyScript = `
local raw = redis.call('GET', KEYS[1])
if not raw then return 'expired' end
local data = cjson.decode(raw)
if data.attempts >= tonumber(ARGV[2]) then
  redis.call('DEL', KEYS[1])
  return 'too_many'
end
if data.code ~= ARGV[1] then
  data.attempts = data.attempts + 1
  local ttl = redis.call('TTL', KEYS[1])
  redis.call('SET', KEYS[1], cjson.encode(data), 'EX', ttl > 0 and ttl or 1)
  return 'wrong'
end
redis.call('DEL', KEYS[1])
return 'ok'
`;

export async function verifyOtp(phone: string, inputCode: string): Promise<void> {
  const result = await redis.eval(verifyScript, 1, otpKey(phone), inputCode, MAX_ATTEMPTS.toString()) as string;

  if (result === 'expired') {
    throw Object.assign(new Error('Code expiré ou non demandé. Demande un nouveau code.'), { status: 400 });
  }
  if (result === 'too_many') {
    throw Object.assign(new Error('Trop de tentatives incorrectes. Demande un nouveau code.'), { status: 429 });
  }
  if (result === 'wrong') {
    throw Object.assign(new Error('Code incorrect.'), { status: 400 });
  }
}
