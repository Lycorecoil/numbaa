import { SiteRow, SectionRow } from '../modules/site/site.service';
import { BusinessRow } from '../modules/business/business.service';
import { ProductRow } from '../modules/product/product.service';

interface BuildInput {
  site: SiteRow & { sections: SectionRow[] };
  business: BusinessRow;
  products: ProductRow[];
}

export function buildHtml({ site, business, products }: BuildInput): string {
  const primary = site.primary_color ?? '#FF7900';
  const sections = [...site.sections].sort((a, b) => a.order - b.order);

  const sectionsHtml = sections.map((s) => buildSection(s, business, products, primary)).join('\n');

  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>${esc(business.name)}</title>
  <style>
    :root { --primary: ${primary}; --primary-light: ${primary}22; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; color: #1a1a1a; background: #fff; }
    section { padding: 60px 20px; max-width: 900px; margin: 0 auto; }
    h1 { font-size: 2rem; font-weight: 800; }
    h2 { font-size: 1.5rem; font-weight: 700; color: var(--primary); margin-bottom: 24px; }
    p { line-height: 1.7; color: #555; }
    .btn { display: inline-block; background: var(--primary); color: #fff; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 700; margin-top: 20px; }
    .hero { background: var(--primary-light); padding: 80px 20px; text-align: center; }
    .hero h1 { color: var(--primary); margin-bottom: 12px; }
    .products-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 20px; }
    .product-card { border: 1px solid #eee; border-radius: 12px; overflow: hidden; }
    .product-card img { width: 100%; height: 160px; object-fit: cover; background: #f5f5f5; }
    .product-card .info { padding: 14px; }
    .product-card .price { font-weight: 700; color: var(--primary); font-size: 1.1rem; }
    .gallery-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; }
    .gallery-grid .placeholder { height: 140px; background: #f0f0f0; border-radius: 8px; }
    .contact-list { list-style: none; }
    .contact-list li { padding: 8px 0; border-bottom: 1px solid #eee; }
    .contact-list a { color: var(--primary); text-decoration: none; }
    footer { background: #1a1a1a; color: #ccc; padding: 40px 20px; text-align: center; }
    footer a { color: var(--primary); text-decoration: none; }
    .testimonial { background: var(--primary-light); border-radius: 12px; padding: 20px; margin-bottom: 16px; font-style: italic; }
    /* Showcase — refined, professional */
    body.showcase h1, body.showcase h2 { font-family: Georgia, 'Times New Roman', serif; }
    body.showcase .btn { border-radius: 4px; letter-spacing: .03em; }
    /* Ecommerce — bold, full-color hero */
    body.ecommerce .hero { background: var(--primary); }
    body.ecommerce .hero h1 { color: #fff; }
    body.ecommerce .hero p { color: rgba(255,255,255,0.85); }
    body.ecommerce .btn { background: #fff; color: var(--primary); font-weight: 800; }
  </style>
</head>
<body class="${site.website_type}">
${sectionsHtml}
</body>
</html>`;
}

function buildSection(
  s: SectionRow,
  business: BusinessRow,
  products: ProductRow[],
  primary: string
): string {
  switch (s.type) {
    case 'hero':
      return `<div class="hero">
  <h1>${esc(s.title || business.name)}</h1>
  <p>${esc(s.content || `Bienvenue chez ${business.name}`)}</p>
  ${business.contact_whatsapp
    ? `<a class="btn" href="https://wa.me/${business.contact_whatsapp.replace(/\D/g, '')}">Nous contacter</a>`
    : ''}
</div>`;

    case 'about':
      return `<section>
  <h2>${esc(s.title || 'À propos')}</h2>
  <p>${esc(s.content || `Découvrez ${business.name}, votre partenaire de confiance.`)}</p>
</section>`;

    case 'services':
      return `<section>
  <h2>${esc(s.title || 'Nos services')}</h2>
  <p>${esc(s.content || 'Nous proposons des services de qualité adaptés à vos besoins.')}</p>
</section>`;

    case 'products':
      return `<section>
  <h2>${esc(s.title || 'Nos produits')}</h2>
  <div class="products-grid">
    ${products.length > 0
      ? products.map((p) => `
    <div class="product-card">
      ${p.image_url
        ? `<img src="${esc(p.image_url)}" alt="${esc(p.name)}"/>`
        : `<div style="height:160px;background:#f5f5f5;display:flex;align-items:center;justify-content:center;color:#999">📦</div>`}
      <div class="info">
        <div style="font-weight:600">${esc(p.name)}</div>
        <div style="font-size:.85rem;color:#777;margin:4px 0">${esc(p.description)}</div>
        <div class="price">${Number(p.price).toLocaleString('fr-FR')} FCFA</div>
      </div>
    </div>`).join('')
      : '<p>Aucun produit pour le moment.</p>'}
  </div>
</section>`;

    case 'gallery':
      return `<section>
  <h2>${esc(s.title || 'Galerie')}</h2>
  <div class="gallery-grid">
    ${[1, 2, 3, 4].map(() => `<div class="placeholder"></div>`).join('')}
  </div>
</section>`;

    case 'testimonials':
      return `<section>
  <h2>${esc(s.title || 'Témoignages')}</h2>
  <div class="testimonial">"${esc(s.content || 'Un service excellent, je recommande vivement !')}"<br/><strong>— Client satisfait</strong></div>
</section>`;

    case 'contact':
      return `<section>
  <h2>${esc(s.title || 'Nous contacter')}</h2>
  <ul class="contact-list">
    ${business.contact_phone ? `<li>📞 <a href="tel:${esc(business.contact_phone)}">${esc(business.contact_phone)}</a></li>` : ''}
    ${business.contact_whatsapp ? `<li>💬 <a href="https://wa.me/${business.contact_whatsapp.replace(/\D/g, '')}">WhatsApp</a></li>` : ''}
    ${business.contact_email ? `<li>✉️ <a href="mailto:${esc(business.contact_email)}">${esc(business.contact_email)}</a></li>` : ''}
  </ul>
</section>`;

    case 'footer':
      return `<footer>
  <p>&copy; ${new Date().getFullYear()} ${esc(business.name)}. Propulsé par <a href="#">NUMBAA</a>.</p>
  <div style="margin-top:12px">
    ${business.social_facebook ? `<a href="${esc(business.social_facebook)}" style="margin:0 8px">Facebook</a>` : ''}
    ${business.social_instagram ? `<a href="${esc(business.social_instagram)}" style="margin:0 8px">Instagram</a>` : ''}
  </div>
</footer>`;

    default:
      return `<section><h2>${esc(s.title)}</h2><p>${esc(s.content)}</p></section>`;
  }
}

function esc(str: string | null | undefined): string {
  if (!str) return '';
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
