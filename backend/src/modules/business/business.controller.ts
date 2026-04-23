import { Request, Response, NextFunction } from 'express';
import path from 'path';
import { env } from '../../config/env';
import * as svc from './business.service';

function formatBusiness(b: svc.BusinessRow) {
  return {
    id: b.id,
    userId: b.user_id,
    name: b.name,
    category: b.category,
    logoPath: b.logo_url,
    contact: {
      phone: b.contact_phone ?? '',
      email: b.contact_email ?? '',
      whatsapp: b.contact_whatsapp ?? '',
    },
    socialLinks: {
      facebook: b.social_facebook ?? '',
      instagram: b.social_instagram ?? '',
      twitter: b.social_twitter ?? '',
      linkedin: b.social_linkedin ?? '',
    },
  };
}

export async function get(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const business = await svc.getByUserId(req.user!.id);
    if (!business) { res.status(404).json({ success: false, message: 'Aucun business trouvé.' }); return; }
    res.json({ success: true, business: formatBusiness(business) });
  } catch (err) { next(err); }
}

export async function create(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { name, category, contact, socialLinks } = req.body;
    const business = await svc.create(req.user!.id, {
      name, category,
      contact_phone: contact?.phone,
      contact_email: contact?.email,
      contact_whatsapp: contact?.whatsapp,
      social_facebook: socialLinks?.facebook,
      social_instagram: socialLinks?.instagram,
      social_twitter: socialLinks?.twitter,
      social_linkedin: socialLinks?.linkedin,
    });
    res.status(201).json({ success: true, business: formatBusiness(business) });
  } catch (err) { next(err); }
}

export async function update(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { name, category, contact, socialLinks } = req.body;
    const business = await svc.update(req.user!.id, {
      name, category,
      contact_phone: contact?.phone,
      contact_email: contact?.email,
      contact_whatsapp: contact?.whatsapp,
      social_facebook: socialLinks?.facebook,
      social_instagram: socialLinks?.instagram,
      social_twitter: socialLinks?.twitter,
      social_linkedin: socialLinks?.linkedin,
    });
    if (!business) { res.status(404).json({ success: false, message: 'Business introuvable.' }); return; }
    res.json({ success: true, business: formatBusiness(business) });
  } catch (err) { next(err); }
}

export async function uploadLogo(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.file) { res.status(400).json({ success: false, message: 'Aucun fichier fourni.' }); return; }
    const logoUrl = `/uploads/${path.basename(req.file.path)}`;
    await svc.updateLogo(req.user!.id, logoUrl);
    res.json({ success: true, logoUrl });
  } catch (err) { next(err); }
}
