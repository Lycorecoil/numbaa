import '../../core/constants/enums.dart';
import '../../domain/entities/template_entity.dart';
import '../../domain/repositories/template_repository.dart';

/// Mock implementation of [TemplateRepository] with hardcoded templates.
class MockTemplateRepository implements TemplateRepository {
  static final List<TemplateEntity> _templates = [
    // --- Showcase templates ---
    const TemplateEntity(
      id: 'tpl_showcase_01',
      name: 'Essentiel',
      description: 'Template epure et professionnel, ideal pour les artisans et services.',
      websiteType: WebsiteType.showcase,
      previewColor: '#FF7900',
      thumbnailIcon: 'business',
      defaultSections: [
        SectionType.hero,
        SectionType.about,
        SectionType.services,
        SectionType.contact,
        SectionType.footer,
      ],
    ),
    const TemplateEntity(
      id: 'tpl_showcase_02',
      name: 'Vitrine Pro',
      description: 'Mise en avant visuelle avec galerie photo et temoignages clients.',
      websiteType: WebsiteType.showcase,
      previewColor: '#333333',
      thumbnailIcon: 'storefront',
      defaultSections: [
        SectionType.hero,
        SectionType.about,
        SectionType.gallery,
        SectionType.testimonials,
        SectionType.contact,
        SectionType.footer,
      ],
    ),
    const TemplateEntity(
      id: 'tpl_showcase_03',
      name: 'Classique',
      description: 'Structure simple et directe pour une presence en ligne rapide.',
      websiteType: WebsiteType.showcase,
      previewColor: '#2E7D32',
      thumbnailIcon: 'language',
      defaultSections: [
        SectionType.hero,
        SectionType.services,
        SectionType.contact,
        SectionType.footer,
      ],
    ),

    // --- E-commerce templates ---
    const TemplateEntity(
      id: 'tpl_ecom_01',
      name: 'Boutique Simple',
      description: 'Catalogue produits avec contact direct par WhatsApp ou telephone.',
      websiteType: WebsiteType.ecommerce,
      previewColor: '#FF7900',
      thumbnailIcon: 'shopping_bag',
      defaultSections: [
        SectionType.hero,
        SectionType.products,
        SectionType.about,
        SectionType.contact,
        SectionType.footer,
      ],
    ),
    const TemplateEntity(
      id: 'tpl_ecom_02',
      name: 'Catalogue Pro',
      description: 'Presentation produits detaillee avec categories et galerie.',
      websiteType: WebsiteType.ecommerce,
      previewColor: '#1565C0',
      thumbnailIcon: 'inventory_2',
      defaultSections: [
        SectionType.hero,
        SectionType.products,
        SectionType.gallery,
        SectionType.testimonials,
        SectionType.contact,
        SectionType.footer,
      ],
    ),
    const TemplateEntity(
      id: 'tpl_ecom_03',
      name: 'Marche Local',
      description: 'Ideal pour les restaurants et artisans avec commande simplifiee.',
      websiteType: WebsiteType.ecommerce,
      previewColor: '#E06800',
      thumbnailIcon: 'restaurant',
      defaultSections: [
        SectionType.hero,
        SectionType.products,
        SectionType.about,
        SectionType.contact,
        SectionType.footer,
      ],
    ),
  ];

  @override
  Future<List<TemplateEntity>> getTemplates() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _templates;
  }

  @override
  Future<List<TemplateEntity>> getTemplatesByType(WebsiteType type) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _templates.where((t) => t.websiteType == type).toList();
  }

  @override
  Future<TemplateEntity?> getTemplateById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
