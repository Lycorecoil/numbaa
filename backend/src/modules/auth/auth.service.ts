import bcrypt from 'bcryptjs';
import { query } from '../../config/database';
import { redis } from '../../config/redis';
import { generateToken } from '../../middlewares/auth.middleware';
import { generateAndSendOtp, verifyOtp } from '../../whatsapp/otp.service';

const SESSION_TTL = 60 * 60 * 24 * 7; // 7 jours

export interface UserRow {
  id: string;
  phone: string;
  name: string;
  language: string;
  has_completed_onboarding: boolean;
  password_hash: string | null;
  created_at: Date;
}

export async function requestOtp(phone: string): Promise<{ debugCode?: string }> {
  const debugCode = await generateAndSendOtp(phone);
  return { debugCode };
}

export async function verifyOtpAndLogin(
  phone: string,
  code: string,
  language: string
): Promise<{ token: string; user: UserRow; needsPassword: boolean }> {
  // Valide le code (lève une erreur si invalide)
  await verifyOtp(phone, code);

  // Trouve ou crée l'utilisateur
  let result = await query<UserRow>(
    'SELECT * FROM users WHERE phone = $1',
    [phone]
  );

  if (result.rows.length === 0) {
    result = await query<UserRow>(
      `INSERT INTO users (phone, language)
       VALUES ($1, $2)
       RETURNING *`,
      [phone, language]
    );
  }

  const user = result.rows[0];

  // Générer JWT et stocker la session Redis
  const token = generateToken({ id: user.id, phone: user.phone });
  await redis.set(`session:${user.id}`, 'valid', 'EX', SESSION_TTL);

  // Créer un plan starter par défaut si le user n'en a pas
  await query(
    `INSERT INTO plans (user_id, name, expires_at, sms_remaining, total_sms, data_remaining_mb, data_total_mb)
     VALUES ($1, 'Starter', NOW() + INTERVAL '30 days', 100, 500, 1024, 2048)
     ON CONFLICT (user_id) DO NOTHING`,
    [user.id]
  );

  return { token, user, needsPassword: !user.password_hash };
}

export async function loginWithPassword(
  phone: string,
  password: string
): Promise<{ token: string; user: UserRow }> {
  const result = await query<UserRow>('SELECT * FROM users WHERE phone = $1', [phone]);
  const user = result.rows[0];
  if (!user || !user.password_hash) {
    throw Object.assign(
      new Error('Compte introuvable ou mot de passe non défini. Utilise le code OTP.'),
      { status: 401 }
    );
  }
  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) {
    throw Object.assign(new Error('Mot de passe incorrect.'), { status: 401 });
  }
  const token = generateToken({ id: user.id, phone: user.phone });
  await redis.set(`session:${user.id}`, 'valid', 'EX', SESSION_TTL);
  return { token, user };
}

export async function setPassword(userId: string, password: string): Promise<void> {
  const hash = await bcrypt.hash(password, 10);
  await query('UPDATE users SET password_hash = $1 WHERE id = $2', [hash, userId]);
}

export async function logout(userId: string): Promise<void> {
  await redis.del(`session:${userId}`);
}

export async function getMe(userId: string): Promise<UserRow | null> {
  const result = await query<UserRow>(
    'SELECT * FROM users WHERE id = $1',
    [userId]
  );
  return result.rows[0] ?? null;
}

export async function markOnboardingComplete(userId: string): Promise<void> {
  await query(
    'UPDATE users SET has_completed_onboarding = TRUE, updated_at = NOW() WHERE id = $1',
    [userId]
  );
}
