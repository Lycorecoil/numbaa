import { query } from '../../config/database';

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

async function loadSections(siteId: string): Promise<SectionRow[]> {
  const r = await query<SectionRow>(
    'SELECT * FROM site_sections WHERE site_id = $1 ORDER BY "order"',
    [siteId]
  );
  return r.rows;
}

export async function getByBusinessId(businessId: string): Promise<SiteRow | null> {
  const r = await query<SiteRow>('SELECT * FROM sites WHERE business_id = $1', [businessId]);
  if (!r.rows[0]) return null;
  const site = r.rows[0];
  site.sections = await loadSections(site.id);
  return site;
}

export async function create(data: {
  businessId: string;
  templateId: string;
  websiteType: string;
  sections: { id: string; type: string; title: string; content: string; order: number }[];
}): Promise<SiteRow> {
  const siteResult = await query<SiteRow>(
    `INSERT INTO sites (business_id, template_id, website_type)
     VALUES ($1, $2, $3) RETURNING *`,
    [data.businessId, data.templateId, data.websiteType]
  );
  const site = siteResult.rows[0];

  for (const s of data.sections) {
    await query(
      `INSERT INTO site_sections (id, site_id, type, title, content, "order")
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [s.id, site.id, s.type, s.title, s.content, s.order]
    );
  }

  site.sections = await loadSections(site.id);
  return site;
}

export async function updateSite(siteId: string, data: {
  sections?: { id: string; type: string; title: string; content: string; order: number }[];
  primaryColor?: string;
  status?: string;
  publishedUrl?: string;
}): Promise<SiteRow | null> {
  await query(
    `UPDATE sites SET
       primary_color = COALESCE($2, primary_color),
       status = COALESCE($3, status),
       published_url = COALESCE($4, published_url),
       updated_at = NOW()
     WHERE id = $1`,
    [siteId, data.primaryColor ?? null, data.status ?? null, data.publishedUrl ?? null]
  );

  if (data.sections) {
    await query('DELETE FROM site_sections WHERE site_id = $1', [siteId]);
    for (const s of data.sections) {
      await query(
        `INSERT INTO site_sections (id, site_id, type, title, content, "order")
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [s.id, siteId, s.type, s.title, s.content, s.order]
      );
    }
  }

  const r = await query<SiteRow>('SELECT * FROM sites WHERE id = $1', [siteId]);
  if (!r.rows[0]) return null;
  const site = r.rows[0];
  site.sections = await loadSections(siteId);
  return site;
}
