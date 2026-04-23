import { query } from '../../config/database';

export interface BusinessRow {
  id: string;
  user_id: string;
  name: string;
  category: string;
  logo_url: string | null;
  contact_phone: string | null;
  contact_email: string | null;
  contact_whatsapp: string | null;
  social_facebook: string | null;
  social_instagram: string | null;
  social_twitter: string | null;
  social_linkedin: string | null;
}

export async function getByUserId(userId: string): Promise<BusinessRow | null> {
  const r = await query<BusinessRow>('SELECT * FROM businesses WHERE user_id = $1', [userId]);
  return r.rows[0] ?? null;
}

export async function create(userId: string, data: Partial<BusinessRow>): Promise<BusinessRow> {
  const r = await query<BusinessRow>(
    `INSERT INTO businesses
       (user_id, name, category, logo_url,
        contact_phone, contact_email, contact_whatsapp,
        social_facebook, social_instagram, social_twitter, social_linkedin)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
     RETURNING *`,
    [
      userId, data.name, data.category, data.logo_url ?? null,
      data.contact_phone ?? null, data.contact_email ?? null, data.contact_whatsapp ?? null,
      data.social_facebook ?? null, data.social_instagram ?? null,
      data.social_twitter ?? null, data.social_linkedin ?? null,
    ]
  );
  return r.rows[0];
}

export async function update(userId: string, data: Partial<BusinessRow>): Promise<BusinessRow | null> {
  const r = await query<BusinessRow>(
    `UPDATE businesses SET
       name = COALESCE($2, name),
       category = COALESCE($3, category),
       logo_url = COALESCE($4, logo_url),
       contact_phone = COALESCE($5, contact_phone),
       contact_email = COALESCE($6, contact_email),
       contact_whatsapp = COALESCE($7, contact_whatsapp),
       social_facebook = COALESCE($8, social_facebook),
       social_instagram = COALESCE($9, social_instagram),
       social_twitter = COALESCE($10, social_twitter),
       social_linkedin = COALESCE($11, social_linkedin),
       updated_at = NOW()
     WHERE user_id = $1
     RETURNING *`,
    [
      userId, data.name, data.category, data.logo_url,
      data.contact_phone, data.contact_email, data.contact_whatsapp,
      data.social_facebook, data.social_instagram,
      data.social_twitter, data.social_linkedin,
    ]
  );
  return r.rows[0] ?? null;
}

export async function updateLogo(userId: string, logoUrl: string): Promise<void> {
  await query('UPDATE businesses SET logo_url = $2, updated_at = NOW() WHERE user_id = $1', [userId, logoUrl]);
}
