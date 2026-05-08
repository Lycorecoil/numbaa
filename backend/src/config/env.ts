import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) throw new Error(`Missing required environment variable: ${key}`);
  return value;
}

function optionalEnv(key: string, defaultValue: string): string {
  return process.env[key] ?? defaultValue;
}

function requireEnvMinLength(key: string, minLength: number): string {
  const value = requireEnv(key);
  if (value.length < minLength) {
    throw new Error(`Environment variable ${key} must be at least ${minLength} characters long`);
  }
  return value;
}

function validateNodeEnv(value: string): 'development' | 'production' | 'test' {
  if (value !== 'development' && value !== 'production' && value !== 'test') {
    throw new Error(`NODE_ENV must be one of: development, production, test. Got: ${value}`);
  }
  return value;
}

export const env = {
  NODE_ENV: validateNodeEnv(optionalEnv('NODE_ENV', 'development')),
  PORT: parseInt(optionalEnv('PORT', '3000'), 10),

  DATABASE_URL: requireEnv('DATABASE_URL'),

  REDIS_URL: optionalEnv('REDIS_URL', 'redis://localhost:6379'),

  JWT_SECRET: requireEnvMinLength('JWT_SECRET', 32),
  JWT_EXPIRY: optionalEnv('JWT_EXPIRY', '7d'),

  VERCEL_TOKEN: optionalEnv('VERCEL_TOKEN', ''),
  VERCEL_TEAM_ID: optionalEnv('VERCEL_TEAM_ID', ''),
  BYPASS_WHATSAPP: optionalEnv('BYPASS_WHATSAPP', 'false') === 'true',

  UPLOAD_DIR: optionalEnv('UPLOAD_DIR', 'uploads'),
  MAX_FILE_SIZE: parseInt(optionalEnv('MAX_FILE_SIZE', '5242880'), 10),

  ALLOWED_ORIGINS: optionalEnv('ALLOWED_ORIGINS', '*'),

  get isProduction(): boolean { return this.NODE_ENV === 'production'; },
  get isDevelopment(): boolean { return this.NODE_ENV === 'development'; },
  get isTest(): boolean { return this.NODE_ENV === 'test'; },
};

export type Env = typeof env;
