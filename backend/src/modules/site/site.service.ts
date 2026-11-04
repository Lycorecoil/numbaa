import { query, withTransaction } from '../../config/database';
import { PoolClient } from 'pg';

export interface SectionRow {
  id: string;
  site_id: string;
  type: string;
  title: string;
  content: string;
  order: number;
}

export interface SiteRow {
  id: string;
  business_id: string;
  template_id: string;
  website_type: string;
  status: string;
  primary_color: string | null;
  published_url: string | null;
  created_at: Date;
  sections?: SectionRow[];
}

async function loadSections(siteId: string, client?: PoolClient): Promise<SectionRow[]> {
  const runQuery = client ? client.query.bind(client) : query;
  const r = await runQuery<SectionRow>(
    'SELECT * FROM site_sections WHERE site_id = $1 ORDER BY "order"',
    [siteId]
  );
  return r.rows;
}

export async function assertSiteOwner(siteId: string, userId: string): Promise<SiteRow> {
  const r = await query<SiteRow>(
    `SELECT s.* FROM sites s
     JOIN businesses b ON b.id = s.business_id
     WHERE s.id = $1 AND b.user_id = $2`,
    [siteId, userId]
  );
  if (!r.rows[0]) {
    throw Object.assign(new Error('Site introuvable ou accès non autorisé.'), { status: 404 });
  }
  return r.rows[0];
}

export async function getByBusinessId(businessId: string): Promise<SiteRow | null> {
  const r = await query<SiteRow>('SELECT * FROM sites WHERE business_id = $1', [businessId]);
  if (!r.rows[0]) return null;
  const site = r.rows[0];
  site.sections = await loadSections(site.id);
  return site;
}

export async function create(userId: string, data: {
  businessId: string;
  templateId: string;
  websiteType: string;
  sections: { id: string; type: string; title: string; content: string; order: number }[];
}): Promise<SiteRow> {
  if (!userId) {
    throw Object.assign(new Error('Authentification requise.'), { status: 401 });
  }
  return withTransaction(async (client) => {
    const business = await client.query(
      'SELECT id FROM businesses WHERE id = $1 AND user_id = $2 FOR SHARE',
      [data.businessId, userId]
    );
    if (!business.rows[0]) {
      throw Object.assign(new Error('Accès non autorisé.'), { status: 403 });
    }
    const siteResult = await client.query<SiteRow>(
      `INSERT INTO sites (business_id, template_id, website_type)
       VALUES ($1, $2, $3) RETURNING *`,
      [data.businessId, data.templateId, data.websiteType]
    );
    const site = siteResult.rows[0];

    for (const s of data.sections) {
      await client.query(
        `INSERT INTO site_sections (id, site_id, type, title, content, "order")
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [s.id, site.id, s.type, s.title, s.content, s.order]
      );
    }

    site.sections = await loadSections(site.id, client);
    return site;
  });
}

export async function deleteSite(siteId: string): Promise<void> {
  // Foreign keys cascade to sections and products in this single atomic statement.
  await query('DELETE FROM sites WHERE id = $1', [siteId]);
}

export async function updateSite(siteId: string, data: {
  sections?: { id: string; type: string; title: string; content: string; order: number }[];
  primaryColor?: string;
  status?: string;
  publishedUrl?: string;
  templateId?: string;
  websiteType?: string;
}): Promise<SiteRow | null> {
  return withTransaction(async (client) => {
    const updated = await client.query<SiteRow>(
      `UPDATE sites SET
         primary_color = COALESCE($2, primary_color),
         status = COALESCE($3, status),
         published_url = COALESCE($4, published_url),
         template_id = COALESCE($5, template_id),
         website_type = COALESCE($6, website_type),
         updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [siteId, data.primaryColor ?? null, data.status ?? null, data.publishedUrl ?? null,
       data.templateId ?? null, data.websiteType ?? null]
    );
    if (!updated.rows[0]) return null;

    if (data.sections) {
      await client.query('DELETE FROM site_sections WHERE site_id = $1', [siteId]);
      for (const s of data.sections) {
        await client.query(
          `INSERT INTO site_sections (id, site_id, type, title, content, "order")
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [s.id, siteId, s.type, s.title, s.content, s.order]
        );
      }
    }

    const site = updated.rows[0];
    site.sections = await loadSections(siteId, client);
    return site;
  });
}
