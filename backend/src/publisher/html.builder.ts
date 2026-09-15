import { SiteRow, SectionRow } from '../modules/site/site.service';
import { BusinessRow } from '../modules/business/business.service';
import { ProductRow } from '../modules/product/product.service';

interface BuildInput {
  site: SiteRow & { sections: SectionRow[] };
  business: BusinessRow;
  products: ProductRow[];
}

const DEFAULT_PRIMARY = '#FF7900';
const HEX_RE = /^#?[0-9a-fA-F]{6}$|^#?[0-9a-fA-F]{3}$/;

export function buildHtml({ site, business, products }: BuildInput): string {
  const primary = normalizeHex(site.primary_color);
  const primaryDark = shade(primary, -16);
  const onPrimary = contrastText(primary);
  const sections = [...site.sections].sort((a, b) => a.order - b.order);

  const navLinks = sections
    .filter((s) => s.type !== 'hero' && s.type !== 'footer')
    .map((s) => `<a href="#${s.type}">${esc(s.title || sectionFallbackTitle(s.type))}</a>`)
    .join('');

  const contactHref = business.contact_whatsapp
    ? `https://wa.me/${business.contact_whatsapp.replace(/\D/g, '')}`
    : business.contact_phone
      ? `tel:${business.contact_phone}`
      : null;
  const contactLabel = business.contact_whatsapp ? 'WhatsApp' : 'Appeler';

  const sectionsHtml = sections.map((s) => buildSection(s, business, products)).join('\n');
  const description = metaDescription(business, sections);
  const favicon = buildFavicon(business.name, primary, onPrimary);

  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>${esc(business.name)}</title>
  <meta name="description" content="${esc(description)}"/>
  <meta name="theme-color" content="${primary}"/>
  <meta property="og:title" content="${esc(business.name)}"/>
  <meta property="og:description" content="${esc(description)}"/>
  <meta property="og:type" content="website"/>
  ${business.logo_url ? `<meta property="og:image" content="${esc(business.logo_url)}"/>` : ''}
  <link rel="icon" href="${favicon}"/>
  <style>
    :root {
      --primary: ${primary};
      --primary-dark: ${primaryDark};
      --primary-light: ${primary}1f;
      --on-primary: ${onPrimary};
      --ink: #1a1a1a;
      --ink-soft: #56555c;
      --muted: #7a7982;
      --surface: #ffffff;
      --surface-soft: #f7f7f9;
      --border: #ececef;
      --radius-sm: 8px;
      --radius-md: 12px;
      --radius-lg: 18px;
      --shadow-sm: 0 1px 2px rgba(20,20,25,.05), 0 1px 3px rgba(20,20,25,.06);
      --shadow-md: 0 8px 24px rgba(20,20,25,.08);
      --ease: cubic-bezier(.22,.61,.36,1);
    }
    * { box-sizing: border-box; }
    html { scroll-behavior: smooth; }
    body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: var(--ink); background: var(--surface); -webkit-font-smoothing: antialiased; }
    img { max-width: 100%; display: block; }
    section, .hero { padding: 64px 24px; max-width: 960px; margin: 0 auto; scroll-margin-top: 76px; }
    h1 { font-size: clamp(1.9rem, 4.5vw, 2.75rem); font-weight: 800; letter-spacing: -.01em; line-height: 1.15; }
    h2 { font-size: clamp(1.35rem, 3vw, 1.75rem); font-weight: 700; color: var(--ink); margin: 0 0 28px; letter-spacing: -.01em; }
    h2::after { content: ''; display: block; width: 40px; height: 3px; background: var(--primary); border-radius: 2px; margin-top: 10px; }
    p { line-height: 1.7; color: var(--ink-soft); margin: 0; }

    /* Header */
    .site-header { position: sticky; top: 0; z-index: 50; background: rgba(255,255,255,.92); backdrop-filter: blur(8px); border-bottom: 1px solid var(--border); }
    .header-inner { max-width: 1080px; margin: 0 auto; padding: 12px 20px; display: flex; align-items: center; gap: 16px; }
    .brand { display: flex; align-items: center; gap: 10px; text-decoration: none; color: var(--ink); font-weight: 700; font-size: 1.05rem; flex-shrink: 0; }
    .brand-logo { width: 32px; height: 32px; border-radius: 8px; object-fit: cover; }
    .nav-links { display: flex; gap: 22px; margin-left: auto; overflow-x: auto; scrollbar-width: none; }
    .nav-links::-webkit-scrollbar { display: none; }
    .nav-links a { color: var(--ink-soft); text-decoration: none; font-size: .92rem; font-weight: 500; white-space: nowrap; transition: color .15s var(--ease); }
    .nav-links a:hover { color: var(--primary); }
    .header-cta { margin-left: 12px; flex-shrink: 0; background: var(--primary); color: var(--on-primary); padding: 9px 16px; border-radius: var(--radius-sm); text-decoration: none; font-weight: 700; font-size: .88rem; transition: background .15s var(--ease), transform .15s var(--ease); }
    .header-cta:hover { background: var(--primary-dark); transform: translateY(-1px); }

    /* Buttons */
    .btn { display: inline-flex; align-items: center; gap: 8px; background: var(--primary); color: var(--on-primary); padding: 15px 30px; border-radius: var(--radius-sm); text-decoration: none; font-weight: 700; margin-top: 24px; box-shadow: var(--shadow-sm); transition: transform .18s var(--ease), box-shadow .18s var(--ease), background .18s var(--ease); }
    .btn:hover { transform: translateY(-2px); box-shadow: var(--shadow-md); background: var(--primary-dark); }
    .btn:active { transform: translateY(0); }

    /* Hero */
    .hero { background: radial-gradient(circle at 15% 20%, var(--primary-light), transparent 60%), var(--surface-soft); padding: 96px 24px; text-align: center; border-bottom: 1px solid var(--border); }
    .hero h1 { color: var(--ink); margin-bottom: 14px; }
    .hero p { font-size: 1.08rem; max-width: 560px; margin: 0 auto; }
    .hero .eyebrow { display: inline-block; color: var(--primary); font-weight: 700; font-size: .82rem; letter-spacing: .06em; text-transform: uppercase; margin-bottom: 14px; }

    /* Hint (honest empty-state) box */
    .hint { display: flex; align-items: flex-start; gap: 10px; background: var(--surface-soft); border: 1px solid var(--border); border-radius: var(--radius-md); padding: 16px 18px; color: var(--muted); }
    .hint svg { flex-shrink: 0; margin-top: 1px; color: var(--muted); }
    .hint p { color: var(--muted); font-size: .94rem; }

    /* Products — swipeable poster stack (see .product-stack below for the
       drag/fling behaviour, implemented in vanilla JS at the bottom of the
       page). Cards are absolutely stacked and repositioned by JS; the CSS
       here only defines what a resting position looks like. */
    .stack-hint { font-size: .87rem; color: var(--muted); margin: -14px 0 22px; }
    .product-stack-wrap { position: relative; max-width: 340px; margin: 0 auto 36px; }
    .product-stack { position: relative; height: 430px; touch-action: pan-y; -webkit-user-select: none; user-select: none; outline: none; }
    .product-stack-track { position: relative; width: 100%; height: 100%; }
    .product-stack-card {
      position: absolute; inset: 0; border-radius: var(--radius-lg); overflow: hidden;
      background: var(--surface); border: 1px solid var(--border);
      box-shadow: 0 18px 40px rgba(20,20,25,.18), 0 4px 10px rgba(20,20,25,.07);
      cursor: grab; will-change: transform, opacity;
      transition: transform .38s cubic-bezier(.34,1.56,.64,1), opacity .3s var(--ease);
      /* Fallback for no-JS / before the script runs: show only the first card. */
      opacity: 0; pointer-events: none; transform: translate3d(0,20px,0) scale(.95); z-index: 1;
    }
    .product-stack-card:first-child { opacity: 1; pointer-events: auto; transform: none; z-index: 10; }
    .product-stack-card:active { cursor: grabbing; }
    .product-stack-card.dragging { transition: none; }
    .product-stack-image { position: absolute; inset: 0; background: var(--surface-soft); }
    .product-stack-image img { width: 100%; height: 100%; object-fit: cover; }
    .product-stack-image .product-thumb-fallback { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; color: var(--muted); background: var(--surface-soft); }
    .product-stack-caption { position: absolute; left: 0; right: 0; bottom: 0; padding: 40px 18px 18px; background: linear-gradient(180deg, transparent, rgba(10,10,12,.8) 60%); }
    .product-stack-category { display: inline-block; font-size: .7rem; font-weight: 700; letter-spacing: .05em; text-transform: uppercase; color: #fff; background: var(--primary); padding: 3px 8px; border-radius: 6px; margin-bottom: 6px; }
    .product-stack-name { font-weight: 700; font-size: 1.05rem; color: #fff; margin-bottom: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .product-stack-price { font-weight: 800; color: #fff; font-size: 1.12rem; }
    .stack-nav-btn { position: absolute; top: 50%; transform: translateY(-50%); width: 40px; height: 40px; border-radius: 50%; background: var(--surface); border: 1px solid var(--border); box-shadow: var(--shadow-sm); display: flex; align-items: center; justify-content: center; color: var(--ink-soft); cursor: pointer; z-index: 20; padding: 0; transition: background .15s var(--ease), color .15s var(--ease); }
    .stack-nav-btn:hover { background: var(--primary); color: var(--on-primary); }
    .stack-nav-btn.prev { left: -14px; } .stack-nav-btn.next { right: -14px; }
    .stack-dots { position: absolute; bottom: -30px; left: 0; right: 0; display: flex; justify-content: center; gap: 6px; }
    .stack-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--border); transition: width .2s var(--ease), background .2s var(--ease); }
    .stack-dot.active { width: 18px; background: var(--primary); }

    /* Gallery (kept ready for when photo upload ships) */
    .gallery-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; }
    .gallery-grid .placeholder { height: 140px; background: var(--surface-soft); border-radius: var(--radius-sm); }

    /* Contact */
    .contact-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 10px; max-width: 420px; }
    .contact-list li { display: flex; align-items: center; gap: 12px; padding: 14px 16px; border: 1px solid var(--border); border-radius: var(--radius-md); background: var(--surface); transition: border-color .15s var(--ease), transform .15s var(--ease); }
    .contact-list li:hover { border-color: var(--primary); transform: translateX(2px); }
    .contact-list svg { color: var(--primary); flex-shrink: 0; }
    .contact-list a { color: var(--ink); text-decoration: none; font-weight: 600; }

    /* Testimonials */
    .testimonial { position: relative; background: var(--surface-soft); border: 1px solid var(--border); border-radius: var(--radius-lg); padding: 32px 28px 26px; margin-bottom: 16px; }
    .testimonial::before { content: '\\201C'; position: absolute; top: 4px; left: 20px; font-size: 3.5rem; color: var(--primary); opacity: .3; font-family: Georgia, serif; line-height: 1; }
    .testimonial p { position: relative; font-size: 1.05rem; color: var(--ink); font-style: italic; }

    /* WhatsApp floating action button */
    .wa-float { position: fixed; right: 20px; bottom: 20px; width: 56px; height: 56px; border-radius: 50%; background: #25D366; color: #fff; display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 20px rgba(0,0,0,.25); text-decoration: none; z-index: 60; animation: wa-pulse 2.6s ease-in-out infinite; }
    .wa-float:hover { animation-play-state: paused; transform: scale(1.06); }
    @keyframes wa-pulse { 0%, 100% { box-shadow: 0 6px 20px rgba(0,0,0,.25), 0 0 0 0 rgba(37,211,102,.45); } 50% { box-shadow: 0 6px 20px rgba(0,0,0,.25), 0 0 0 10px rgba(37,211,102,0); } }

    /* Footer */
    footer { background: #17171a; color: #b9b9bf; padding: 48px 24px 32px; text-align: center; }
    footer .socials { display: flex; justify-content: center; gap: 14px; margin-bottom: 18px; }
    footer .socials a { width: 38px; height: 38px; border-radius: 50%; background: rgba(255,255,255,.08); color: #fff; display: flex; align-items: center; justify-content: center; text-decoration: none; transition: background .15s var(--ease), transform .15s var(--ease); }
    footer .socials a:hover { background: var(--primary); transform: translateY(-2px); }
    footer p { color: #8b8a92; font-size: .88rem; }
    footer .brand-mark { color: var(--primary); font-weight: 700; }

    @media (max-width: 640px) {
      .nav-links { display: none; }
      section, .hero { padding: 48px 20px; }
      .wa-float { right: 16px; bottom: 16px; }
      .product-stack { height: 380px; }
      .stack-nav-btn { display: none; }
    }

    @media (prefers-reduced-motion: reduce) {
      html { scroll-behavior: auto; }
      *, *::before, *::after { animation-duration: .001ms !important; animation-iteration-count: 1 !important; transition-duration: .001ms !important; }
    }

    /* Showcase — refined, editorial */
    body.showcase h1, body.showcase h2 { font-family: Georgia, 'Times New Roman', serif; }
    body.showcase .btn { border-radius: 4px; letter-spacing: .03em; }
    body.showcase .product-stack-card, body.showcase .contact-list li { border-radius: var(--radius-sm); }

    /* Ecommerce — bold, full-color hero */
    body.ecommerce .hero { background: linear-gradient(160deg, var(--primary), var(--primary-dark)); border-bottom: none; }
    body.ecommerce .hero h1, body.ecommerce .hero .eyebrow { color: var(--on-primary); }
    body.ecommerce .hero p { color: color-mix(in srgb, var(--on-primary) 85%, transparent); }
    body.ecommerce .hero .btn { background: var(--on-primary); color: var(--primary); }
    body.ecommerce .hero .btn:hover { background: var(--on-primary); opacity: .92; }
  </style>
</head>
<body class="${site.website_type}">
  <header class="site-header">
    <div class="header-inner">
      <a href="#" class="brand">
        ${business.logo_url ? `<img src="${esc(business.logo_url)}" alt="" class="brand-logo" onerror="this.remove()"/>` : ''}
        <span>${esc(business.name)}</span>
      </a>
      ${navLinks ? `<nav class="nav-links">${navLinks}</nav>` : ''}
      ${contactHref ? `<a class="header-cta" href="${contactHref}">${contactLabel}</a>` : ''}
    </div>
  </header>

${sectionsHtml}

  ${business.contact_whatsapp ? `<a class="wa-float" href="https://wa.me/${business.contact_whatsapp.replace(/\D/g, '')}" aria-label="Contacter sur WhatsApp">${icon('chat', 28)}</a>` : ''}
  ${productStackScript()}
</body>
</html>`;
}

/** Vanilla-JS drag/fling behaviour for the ".product-stack" poster carousel
 * (see the "products" case in buildSection and the matching CSS above).
 * No external library: touch/mouse tracking plus CSS transitions do the
 * animation work on the compositor thread, which is cheap enough for
 * entry-level Android hardware and stays fluid whether there are 2 products
 * or 20 — only cards within a small render window around the active index
 * are ever painted (see `within` below). Click/arrow-key fallback covers
 * desktop and non-touch input. */
function productStackScript(): string {
  return `<script>
(function () {
  var stacks = document.querySelectorAll('.product-stack');
  stacks.forEach(initStack);

  function initStack(stack) {
    var track = stack.querySelector('.product-stack-track');
    if (!track) return;
    var cards = Array.prototype.slice.call(track.querySelectorAll('.product-stack-card'));
    var count = cards.length;
    if (count === 0) return;
    var current = 0;
    var dotsWrap = stack.querySelector('.stack-dots');
    var prevBtn = stack.querySelector('.stack-nav-btn.prev');
    var nextBtn = stack.querySelector('.stack-nav-btn.next');
    var WINDOW_BACK = 2, WINDOW_FRONT = 3;

    if (dotsWrap && count > 1) {
      for (var d = 0; d < count; d++) {
        var dot = document.createElement('span');
        dot.className = 'stack-dot' + (d === 0 ? ' active' : '');
        dotsWrap.appendChild(dot);
      }
    }
    if (count <= 1) {
      if (prevBtn) prevBtn.style.display = 'none';
      if (nextBtn) nextBtn.style.display = 'none';
    }

    function within(offset) { return offset >= -WINDOW_BACK && offset <= WINDOW_FRONT; }

    function render() {
      cards.forEach(function (card, i) {
        var offset = i - current;
        if (!within(offset)) { card.style.display = 'none'; return; }
        card.style.display = '';
        var t, opacity, z, rotate;
        if (offset === 0) {
          t = 'translate3d(0,0,0)'; rotate = 0; opacity = 1; z = count + 10;
        } else if (offset > 0) {
          var depth = Math.min(offset, 3);
          t = 'translate3d(0,' + (depth * 12) + 'px,0)';
          rotate = (depth % 2 === 0 ? 1 : -1) * depth * 2.2;
          opacity = Math.max(1 - depth * 0.16, 0.35);
          z = count - depth;
        } else {
          t = 'translate3d(-130%,0,0)'; rotate = -8; opacity = 0; z = 0;
        }
        card.style.zIndex = String(z);
        card.style.opacity = String(opacity);
        card.style.transform = t + ' rotate(' + rotate + 'deg)';
        card.style.pointerEvents = offset === 0 ? 'auto' : 'none';
      });
      if (dotsWrap) {
        var dots = dotsWrap.children;
        for (var k = 0; k < dots.length; k++) dots[k].classList.toggle('active', k === current);
      }
      if (prevBtn) prevBtn.style.visibility = current === 0 ? 'hidden' : 'visible';
      if (nextBtn) nextBtn.style.visibility = current === count - 1 ? 'hidden' : 'visible';
    }

    function goTo(index) {
      current = Math.max(0, Math.min(count - 1, index));
      render();
    }

    if (prevBtn) prevBtn.addEventListener('click', function () { goTo(current - 1); });
    if (nextBtn) nextBtn.addEventListener('click', function () { goTo(current + 1); });
    stack.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowLeft') goTo(current - 1);
      else if (e.key === 'ArrowRight') goTo(current + 1);
    });

    var dragging = false, startX = 0, startY = 0, dx = 0, lockedAxis = null, startTime = 0;
    function topCard() { return cards[current]; }

    function onStart(x, y) {
      dragging = true; startX = x; startY = y; dx = 0; lockedAxis = null; startTime = Date.now();
      topCard().classList.add('dragging');
    }
    function onMove(x, y, evt) {
      if (!dragging) return;
      var ddx = x - startX, ddy = y - startY;
      if (lockedAxis === null && (Math.abs(ddx) > 6 || Math.abs(ddy) > 6)) {
        lockedAxis = Math.abs(ddx) > Math.abs(ddy) ? 'x' : 'y';
      }
      if (lockedAxis === 'y') return;
      if (evt && evt.cancelable) evt.preventDefault();
      dx = ddx;
      var card = topCard();
      var rotate = Math.max(-16, Math.min(16, dx / 12));
      card.style.transform = 'translate3d(' + dx + 'px,0,0) rotate(' + rotate + 'deg)';
      card.style.opacity = String(Math.max(1 - Math.abs(dx) / 400, 0.6));
    }
    function onEnd() {
      if (!dragging) return;
      dragging = false;
      var card = topCard();
      card.classList.remove('dragging');
      var elapsed = Math.max(1, Date.now() - startTime);
      var velocity = dx / elapsed;
      var width = stack.clientWidth || 300;
      var committed = lockedAxis === 'x' && (Math.abs(dx) > width * 0.26 || Math.abs(velocity) > 0.55);
      if (committed) {
        current = dx < 0 ? Math.min(count - 1, current + 1) : Math.max(0, current - 1);
      }
      card.style.opacity = '';
      render();
      lockedAxis = null;
    }

    stack.addEventListener('touchstart', function (e) { var t = e.touches[0]; onStart(t.clientX, t.clientY); }, { passive: true });
    stack.addEventListener('touchmove', function (e) { var t = e.touches[0]; onMove(t.clientX, t.clientY, e); }, { passive: false });
    stack.addEventListener('touchend', onEnd, { passive: true });
    stack.addEventListener('touchcancel', onEnd, { passive: true });

    stack.addEventListener('mousedown', function (e) { onStart(e.clientX, e.clientY); e.preventDefault(); });
    window.addEventListener('mousemove', function (e) { if (dragging) onMove(e.clientX, e.clientY); });
    window.addEventListener('mouseup', onEnd);

    render();
  }
})();
</script>`;
}

function buildSection(s: SectionRow, business: BusinessRow, products: ProductRow[]): string {
  switch (s.type) {
    case 'hero':
      return `  <div class="hero" id="hero">
    <span class="eyebrow">${esc(business.category || 'Bienvenue')}</span>
    <h1>${esc(s.title || business.name)}</h1>
    <p>${esc(s.content || `Bienvenue chez ${business.name}`)}</p>
    ${business.contact_whatsapp
      ? `<a class="btn" href="https://wa.me/${business.contact_whatsapp.replace(/\D/g, '')}">${icon('chat', 18)} Nous contacter</a>`
      : business.contact_phone
        ? `<a class="btn" href="tel:${esc(business.contact_phone)}">${icon('phone', 18)} Nous contacter</a>`
        : ''}
  </div>`;

    case 'about':
      return `  <section id="about">
    <h2>${esc(s.title || 'À propos')}</h2>
    <p>${esc(s.content || `Découvrez ${business.name}, votre partenaire de confiance.`)}</p>
  </section>`;

    case 'services':
      return `  <section id="services">
    <h2>${esc(s.title || 'Nos services')}</h2>
    ${s.content
      ? `<p>${esc(s.content)}</p>`
      : hint('Description des services à venir.')}
  </section>`;

    case 'products': {
      if (products.length === 0) {
        return `  <section id="products">
    <h2>${esc(s.title || 'Nos produits')}</h2>
    ${hint('Aucun produit pour le moment.')}
  </section>`;
      }

      // A swipeable stack of "poster" cards (big photo, name/price over a
      // bottom scrim) instead of a static grid — the JS at the bottom of
      // the page (see the <script> before </body>) handles the drag/fling
      // physics; the markup here just lists every card so it degrades to
      // showing the first product if JS is ever slow to attach (see the
      // `.product-stack-card:first-child` fallback rule in <style>).
      const cards = products.map((p, i) => `
      <article class="product-stack-card" data-index="${i}">
        <div class="product-stack-image">
          ${p.image_url
            ? `<img src="${esc(p.image_url)}" alt="${esc(p.name)}" loading="lazy" draggable="false" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"/>
          <div class="product-thumb-fallback">${icon('package', 34)}</div>`
            : `<div class="product-thumb-fallback" style="display:flex">${icon('package', 34)}</div>`}
        </div>
        <div class="product-stack-caption">
          ${p.category ? `<span class="product-stack-category">${esc(p.category)}</span>` : ''}
          <div class="product-stack-name">${esc(p.name)}</div>
          <div class="product-stack-price">${Number(p.price).toLocaleString('fr-FR')} FCFA</div>
        </div>
      </article>`).join('');

      const navControls = products.length > 1 ? `
      <button type="button" class="stack-nav-btn prev" aria-label="Produit précédent">${icon('chevron-left', 20)}</button>
      <button type="button" class="stack-nav-btn next" aria-label="Produit suivant">${icon('chevron-right', 20)}</button>
      <div class="stack-dots"></div>` : '';

      return `  <section id="products">
    <h2>${esc(s.title || 'Nos produits')}</h2>
    ${products.length > 1 ? `<p class="stack-hint">Glissez pour découvrir nos produits &rarr;</p>` : ''}
    <div class="product-stack-wrap">
      <div class="product-stack" tabindex="0" role="region" aria-roledescription="carousel" aria-label="${esc(s.title || 'Nos produits')}">
        <div class="product-stack-track">${cards}</div>
        ${navControls}
      </div>
    </div>
  </section>`;
    }

    case 'gallery':
      // There is currently no way for a merchant to attach real gallery
      // photos (unlike products, which do have an upload flow) — so
      // showing empty placeholder boxes would look like a broken page to
      // every visitor, forever. Be honest about it instead, the same way
      // "products"/"services" fall back to a plain message when empty.
      return `  <section id="gallery">
    <h2>${esc(s.title || 'Galerie')}</h2>
    ${hint('Galerie photo bientôt disponible.')}
  </section>`;

    case 'testimonials':
      // Never fabricate a customer quote: only render one the merchant
      // actually wrote, otherwise show an honest empty message.
      if (!s.content) {
        return `  <section id="testimonials">
    <h2>${esc(s.title || 'Témoignages')}</h2>
    ${hint('Aucun avis client pour le moment.')}
  </section>`;
      }
      return `  <section id="testimonials">
    <h2>${esc(s.title || 'Témoignages')}</h2>
    <div class="testimonial"><p>${esc(s.content)}</p></div>
  </section>`;

    case 'contact': {
      const rows = [
        business.contact_phone
          ? `<li>${icon('phone')}<a href="tel:${esc(business.contact_phone)}">${esc(business.contact_phone)}</a></li>`
          : '',
        business.contact_whatsapp
          ? `<li>${icon('chat')}<a href="https://wa.me/${business.contact_whatsapp.replace(/\D/g, '')}">WhatsApp : ${esc(business.contact_whatsapp)}</a></li>`
          : '',
        business.contact_email
          ? `<li>${icon('mail')}<a href="mailto:${esc(business.contact_email)}">${esc(business.contact_email)}</a></li>`
          : '',
      ].filter(Boolean).join('');
      return `  <section id="contact">
    <h2>${esc(s.title || 'Nous contacter')}</h2>
    ${rows ? `<ul class="contact-list">${rows}</ul>` : hint('Aucune coordonnée renseignée pour le moment.')}
  </section>`;
    }

    case 'footer': {
      const socials = [
        business.social_facebook ? `<a href="${esc(business.social_facebook)}" aria-label="Facebook">${icon('facebook')}</a>` : '',
        business.social_instagram ? `<a href="${esc(business.social_instagram)}" aria-label="Instagram">${icon('instagram')}</a>` : '',
        business.social_twitter ? `<a href="${esc(business.social_twitter)}" aria-label="Twitter">${icon('twitter')}</a>` : '',
        business.social_linkedin ? `<a href="${esc(business.social_linkedin)}" aria-label="LinkedIn">${icon('linkedin')}</a>` : '',
      ].filter(Boolean).join('');
      return `  <footer>
    ${socials ? `<div class="socials">${socials}</div>` : ''}
    <p>&copy; ${new Date().getFullYear()} ${esc(business.name)}. Propulsé par <span class="brand-mark">NUMBAA</span>.</p>
  </footer>`;
    }

    default:
      return `  <section><h2>${esc(s.title)}</h2><p>${esc(s.content)}</p></section>`;
  }
}

function hint(message: string): string {
  return `<div class="hint">${icon('info', 18)}<p>${esc(message)}</p></div>`;
}

function sectionFallbackTitle(type: string): string {
  switch (type) {
    case 'about': return 'À propos';
    case 'services': return 'Services';
    case 'products': return 'Produits';
    case 'gallery': return 'Galerie';
    case 'testimonials': return 'Avis';
    case 'contact': return 'Contact';
    default: return '';
  }
}

function metaDescription(business: BusinessRow, sections: SectionRow[]): string {
  const hero = sections.find((s) => s.type === 'hero');
  const about = sections.find((s) => s.type === 'about');
  const text = hero?.content || about?.content
    || `${business.name} — ${business.category || 'entreprise locale'}. Contactez-nous pour en savoir plus.`;
  return text.length > 160 ? `${text.slice(0, 157)}...` : text;
}

function buildFavicon(name: string, primary: string, onPrimary: string): string {
  const initial = esc((name || '?').trim().charAt(0).toUpperCase() || '?');
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="14" fill="${primary}"/><text x="32" y="43" font-family="Arial, sans-serif" font-size="30" font-weight="700" fill="${onPrimary}" text-anchor="middle">${initial}</text></svg>`;
  return `data:image/svg+xml,${encodeURIComponent(svg)}`;
}

/** A small, consistent line-icon set (Feather-style) so the published site
 * never falls back to emoji glyphs, which render inconsistently across
 * devices and look unprofessional on a real business's storefront. */
function icon(name: string, size = 18): string {
  const paths: Record<string, string> = {
    phone: '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"/>',
    mail: '<path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/>',
    chat: '<path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>',
    package: '<path d="M16.5 9.4 7.55 4.24"/><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.29 7 12 12 20.71 7"/><line x1="12" y1="22" x2="12" y2="12"/>',
    info: '<circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>',
    facebook: '<path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"/>',
    instagram: '<rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/>',
    twitter: '<path d="M23 3a10.9 10.9 0 0 1-3.14 1.53 4.48 4.48 0 0 0-7.86 3v1A10.66 10.66 0 0 1 3 4s-4 9 5 13a11.64 11.64 0 0 1-7 2c9 5 20 0 20-11.5a4.5 4.5 0 0 0-.08-.83A7.72 7.72 0 0 0 23 3z"/>',
    linkedin: '<path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"/><rect x="2" y="9" width="4" height="12"/><circle cx="4" cy="4" r="2"/>',
    'chevron-left': '<polyline points="15 18 9 12 15 6"/>',
    'chevron-right': '<polyline points="9 18 15 12 9 6"/>',
  };
  const p = paths[name] ?? '';
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${p}</svg>`;
}

function normalizeHex(value: string | null | undefined): string {
  if (!value || !HEX_RE.test(value)) return DEFAULT_PRIMARY;
  return value.startsWith('#') ? value : `#${value}`;
}

/** Darkens (negative percent) or lightens (positive) a hex color — used to
 * derive a hover/active shade from the merchant's chosen primary color
 * without asking them to pick two colors. */
function shade(hex: string, percent: number): string {
  const num = parseInt(hex.replace('#', ''), 16);
  const clamp = (v: number) => Math.max(0, Math.min(255, v));
  const r = clamp((num >> 16) + Math.round(2.55 * percent));
  const g = clamp(((num >> 8) & 0x00ff) + Math.round(2.55 * percent));
  const b = clamp((num & 0x0000ff) + Math.round(2.55 * percent));
  return `#${((1 << 24) | (r << 16) | (g << 8) | b).toString(16).slice(1)}`;
}

/** Picks black or white text for readability on top of an arbitrary
 * merchant-chosen primary color (WCAG-ish YIQ contrast heuristic), so a
 * light brand color never ends up with unreadable white-on-white buttons. */
function contrastText(hex: string): string {
  const num = parseInt(hex.replace('#', ''), 16);
  const r = (num >> 16) & 0xff;
  const g = (num >> 8) & 0xff;
  const b = num & 0xff;
  const yiq = (r * 299 + g * 587 + b * 114) / 1000;
  return yiq >= 150 ? '#1a1a1a' : '#ffffff';
}

function esc(str: string | null | undefined): string {
  if (!str) return '';
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
