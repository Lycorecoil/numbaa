import { Request, Response, NextFunction } from 'express';
import * as svc from './site.service';
import { buildHtml } from '../../publisher/html.builder';
import { deployToVercel } from '../../publisher/vercel.deployer';
import { updateSite } from './site.service';
import { getByUserId } from '../business/business.service';
import { query } from '../../config/database';

function formatSite(s: svc.SiteRow) {
  return {
    id: s.id,
    businessId: s.business_id,
    templateId: s.template_id,
    websiteType: s.website_type,
    status: s.status,
    primaryColor: s.primary_color,
    publishedUrl: s.published_url,
    createdAt: s.created_at,
    sections: (s.sections ?? []).map((sec) => ({
      id: sec.id,
      type: sec.type,
      title: sec.title,
      content: sec.content,
      order: sec.order,
    })),
  };
}

export async function getByBusiness(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const businessId = req.params['businessId']!;
    // Verify the business belongs to the authenticated user
    const biz = await getByUserId(req.user!.id);
    if (!biz || biz.id !== businessId) {
      res.status(403).json({ success: false, message: 'Accès non autorisé.' });
      return;
    }
    const site = await svc.getByBusinessId(businessId);
    if (!site) { res.status(404).json({ success: false, message: 'Aucun site trouvé.' }); return; }
    res.json({ success: true, site: formatSite(site) });
  } catch (err) { next(err); }
}

export async function create(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { businessId, templateId, websiteType, sections } = req.body;
    const site = await svc.create({ businessId, templateId, websiteType, sections: sections ?? [] });
    res.status(201).json({ success: true, site: formatSite(site) });
  } catch (err) { next(err); }
}

export async function update(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const siteId = req.params['siteId']!;
    await svc.assertSiteOwner(siteId, req.user!.id);
    const { sections, primaryColor, templateId, websiteType } = req.body;
    const site = await svc.updateSite(siteId, { sections, primaryColor, templateId, websiteType });
    if (!site) { res.status(404).json({ success: false, message: 'Site introuvable.' }); return; }
    res.json({ success: true, site: formatSite(site) });
  } catch (err) { next(err); }
}

export async function publish(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const siteId = req.params['siteId']!;

    // Verify ownership and load site
    const siteRow = await svc.assertSiteOwner(siteId, req.user!.id);

    const business = await getByUserId(req.user!.id);
    if (!business) { res.status(404).json({ success: false, message: 'Business introuvable.' }); return; }

    const sectionsResult = await query('SELECT * FROM site_sections WHERE site_id = $1 ORDER BY "order"', [siteId]);
    const productsResult = await query('SELECT * FROM products WHERE site_id = $1', [siteId]);

    // Générer HTML
    const html = buildHtml({
      site: { ...siteRow, sections: sectionsResult.rows as svc.SectionRow[] },
      business,
      products: productsResult.rows,
    });

    // Déployer sur Vercel
    const deployedUrl = await deployToVercel(business.id, business.name, html);

    // Mettre à jour le statut
    const updatedSite = await updateSite(siteId, {
      status: 'published',
      publishedUrl: deployedUrl,
    });

    res.json({ success: true, site: formatSite(updatedSite!), url: deployedUrl });
  } catch (err) { next(err); }
}
