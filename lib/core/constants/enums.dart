/// Language preference of the user.
enum AppLanguage {
  french('Francais'),
  moore('Moore');

  final String label;
  const AppLanguage(this.label);
}

/// Category of the business.
enum BusinessCategory {
  commerce('Commerce de detail'),
  restaurant('Restaurant / Alimentation'),
  service('Service'),
  technologie('Technologie'),
  education('Education'),
  autre('Autre');

  final String label;
  const BusinessCategory(this.label);
}

/// Type of website the user wants to generate.
enum WebsiteType {
  showcase('Site Vitrine'),
  ecommerce('Site E-commerce');

  final String label;
  const WebsiteType(this.label);
}

/// Status of a site project.
enum SiteStatus {
  draft('Brouillon'),
  published('Publie');

  final String label;
  const SiteStatus(this.label);
}

/// Types of editable sections in a website.
enum SectionType {
  hero('Hero'),
  about('A propos'),
  services('Services'),
  gallery('Galerie'),
  products('Produits'),
  contact('Contact'),
  testimonials('Temoignages'),
  footer('Pied de page');

  final String label;
  const SectionType(this.label);
}
