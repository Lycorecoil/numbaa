import { Request, Response, NextFunction } from 'express';
import * as svc from './template.service';

function formatTemplate(t: svc.TemplateRow) {
  return {
    id: t.id,
    name: t.name,
    description: t.description,
    websiteType: t.website_type,
    defaultSections: t.default_sections,
    previewColor: t.preview_color,
    thumbnailIcon: t.thumbnail_icon,
  };
}

export async function getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const type = req.query['type'] as string | undefined;
    const rows = type ? await svc.getTemplatesByType(type) : await svc.getTemplates();
    res.json({ success: true, templates: rows.map(formatTemplate) });
  } catch (err) { next(err); }
}

export async function getById(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const template = await svc.getTemplateById(req.params['id'] as string);
    if (!template) { res.status(404).json({ success: false, message: 'Template introuvable.' }); return; }
    res.json({ success: true, template: formatTemplate(template) });
  } catch (err) { next(err); }
}
