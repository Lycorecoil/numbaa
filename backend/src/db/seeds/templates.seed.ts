import { pool } from '../../config/database';
import '../../config/env';

const templates = [
  {
    id: 'tpl_showcase_01',
    name: 'Essentiel',
    description: 'Template épuré et professionnel, idéal pour les artisans et services.',
    website_type: 'showcase',
    default_sections: ['hero', 'about', 'services', 'contact', 'footer'],
    preview_color: '#FF7900',
    thumbnail_icon: 'business',
  },
  {
    id: 'tpl_showcase_02',
    name: 'Vitrine Pro',
    description: 'Mise en avant visuelle avec galerie photo et témoignages clients.',
    website_type: 'showcase',
    default_sections: ['hero', 'about', 'gallery', 'testimonials', 'contact', 'footer'],
    preview_color: '#333333',
    thumbnail_icon: 'storefront',
  },
  {
    id: 'tpl_showcase_03',
    name: 'Classique',
    description: 'Structure simple et directe pour une présence en ligne rapide.',
    website_type: 'showcase',
    default_sections: ['hero', 'services', 'contact', 'footer'],
    preview_color: '#2E7D32',
    thumbnail_icon: 'language',
  },
  {
    id: 'tpl_ecom_01',
    name: 'Boutique Simple',
    description: 'Catalogue produits avec contact direct par WhatsApp ou téléphone.',
    website_type: 'ecommerce',
    default_sections: ['hero', 'products', 'about', 'contact', 'footer'],
    preview_color: '#FF7900',
    thumbnail_icon: 'shopping_bag',
  },
  {
    id: 'tpl_ecom_02',
    name: 'Catalogue Pro',
    description: 'Présentation produits détaillée avec catégories et galerie.',
    website_type: 'ecommerce',
    default_sections: ['hero', 'products', 'gallery', 'testimonials', 'contact', 'footer'],
    preview_color: '#1565C0',
    thumbnail_icon: 'inventory_2',
  },
  {
    id: 'tpl_ecom_03',
    name: 'Marché Local',
    description: 'Idéal pour les restaurants et artisans avec commande simplifiée.',
    website_type: 'ecommerce',
    default_sections: ['hero', 'products', 'about', 'contact', 'footer'],
    preview_color: '#E06800',
    thumbnail_icon: 'restaurant',
  },
];

async function seed(): Promise<void> {
  console.log('[Seed] Inserting templates...');
  for (const t of templates) {
    await pool.query(
      `INSERT INTO templates (id, name, description, website_type, default_sections, preview_color, thumbnail_icon)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (id) DO UPDATE SET
         name = EXCLUDED.name,
         description = EXCLUDED.description,
         default_sections = EXCLUDED.default_sections,
         preview_color = EXCLUDED.preview_color,
         thumbnail_icon = EXCLUDED.thumbnail_icon`,
      [t.id, t.name, t.description, t.website_type, t.default_sections, t.preview_color, t.thumbnail_icon]
    );
  }
  console.log(`[Seed] ${templates.length} templates insérés.`);
  await pool.end();
}

seed().catch((err) => {
  console.error('[Seed] Error:', err);
  process.exit(1);
});
