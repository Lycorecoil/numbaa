-- Migration 001 : Schéma initial NUMBAA

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users
CREATE TABLE IF NOT EXISTS users (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone        VARCHAR(20) UNIQUE NOT NULL,
  name         VARCHAR(100) NOT NULL DEFAULT '',
  language     VARCHAR(10) NOT NULL DEFAULT 'french',
  has_completed_onboarding BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Businesses (1 par user)
CREATE TABLE IF NOT EXISTS businesses (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name              VARCHAR(100) NOT NULL,
  category          VARCHAR(20) NOT NULL,
  logo_url          TEXT,
  contact_phone     VARCHAR(20),
  contact_email     VARCHAR(150),
  contact_whatsapp  VARCHAR(20),
  social_facebook   TEXT,
  social_instagram  TEXT,
  social_twitter    TEXT,
  social_linkedin   TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Templates (données de seed)
CREATE TABLE IF NOT EXISTS templates (
  id               VARCHAR(30) PRIMARY KEY,
  name             VARCHAR(60) NOT NULL,
  description      TEXT,
  website_type     VARCHAR(15) NOT NULL,
  default_sections TEXT[] NOT NULL,
  preview_color    VARCHAR(10) NOT NULL DEFAULT '#FF7900',
  thumbnail_icon   VARCHAR(40) NOT NULL DEFAULT 'web'
);

-- Sites (1 par business)
CREATE TABLE IF NOT EXISTS sites (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  template_id   VARCHAR(30) NOT NULL REFERENCES templates(id),
  website_type  VARCHAR(15) NOT NULL,
  status        VARCHAR(10) NOT NULL DEFAULT 'draft',
  primary_color VARCHAR(10),
  published_url TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(business_id)
);

-- Sections de site
CREATE TABLE IF NOT EXISTS site_sections (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id  UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
  type     VARCHAR(20) NOT NULL,
  title    VARCHAR(200) NOT NULL DEFAULT '',
  content  TEXT NOT NULL DEFAULT '',
  "order"  INTEGER NOT NULL DEFAULT 0
);

-- Produits
CREATE TABLE IF NOT EXISTS products (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id     UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
  name        VARCHAR(150) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price       NUMERIC(12, 2) NOT NULL DEFAULT 0,
  image_url   TEXT,
  category    VARCHAR(80) NOT NULL DEFAULT ''
);

-- Plans d'abonnement (1 par user)
CREATE TABLE IF NOT EXISTS plans (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name              VARCHAR(60) NOT NULL,
  expires_at        TIMESTAMPTZ NOT NULL,
  sms_remaining     INTEGER NOT NULL DEFAULT 0,
  total_sms         INTEGER NOT NULL DEFAULT 0,
  data_remaining_mb INTEGER NOT NULL DEFAULT 0,
  data_total_mb     INTEGER NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);
