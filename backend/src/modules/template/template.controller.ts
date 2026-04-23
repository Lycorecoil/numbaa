import { Request, Response, NextFunction } from 'express';
import * as svc from './template.service';

export async function getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const type = req.query['type'] as string | undefined;
    const templates = type ? await svc.getTemplatesByType(type) : await svc.getTemplates();
    res.json({ success: true, templates });
  } catch (err) { next(err); }
}

export async function getById(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const template = await svc.getTemplateById(req.params['id']!);
    if (!template) { res.status(404).json({ success: false, message: 'Template introuvable.' }); return; }
    res.json({ success: true, template });
  } catch (err) { next(err); }
}
