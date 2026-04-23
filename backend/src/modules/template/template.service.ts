import { query } from '../../config/database';

export interface TemplateRow {
  id: string;
  name: string;
  description: string;
  website_type: string;
  default_sections: string[];
  preview_color: string;
  thumbnail_icon: string;
}

export async function getTemplates(): Promise<TemplateRow[]> {
  const result = await query<TemplateRow>('SELECT * FROM templates ORDER BY website_type, id');
  return result.rows;
}

export async function getTemplatesByType(type: string): Promise<TemplateRow[]> {
  const result = await query<TemplateRow>(
    'SELECT * FROM templates WHERE website_type = $1 ORDER BY id',
    [type]
  );
  return result.rows;
}

export async function getTemplateById(id: string): Promise<TemplateRow | null> {
  const result = await query<TemplateRow>('SELECT * FROM templates WHERE id = $1', [id]);
  return result.rows[0] ?? null;
}
