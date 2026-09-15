import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/site_entity.dart';
import 'card_swipe_stack.dart';
import 'resolved_image.dart';

/// Renders a full mock website preview using Flutter widgets.
/// Shared between PreviewScreen and TemplateCatalogScreen.
///
/// When [business] is provided (real editing/preview flow), the contact
/// section reflects the merchant's actual phone/WhatsApp/email — the same
/// data the published HTML uses — so the preview never shows visitors
/// contact details that don't exist. When [business] is null (template
/// gallery browsing, before any real business/site exists), an
/// illustrative example is shown instead.
class SitePreviewWidget extends StatelessWidget {
  final SiteEntity site;
  final List<ProductEntity> products;
  final BusinessEntity? business;

  /// When true, section titles/free-text content become tap-to-edit inline
  /// fields and sections become long-press-to-drag reorderable — used by
  /// the fullscreen "tap a template card" live editor. Defaults to false so
  /// every other consumer (dashboard preview, template gallery cards,
  /// read-only site preview) keeps exactly the same behavior it always had.
  final bool editable;

  /// Fired with the updated section whenever an inline edit is committed
  /// (only relevant when [editable] is true).
  final ValueChanged<SiteSection>? onSectionChanged;

  /// Fired with (oldIndex, newIndex), already adjusted for the removal of
  /// the dragged item (same contract as [ReorderableListView.onReorderItem]
  /// — pass straight through without any extra `if (newIndex > oldIndex)`
  /// adjustment), when the user drags a section to a new position (only
  /// relevant when [editable] is true).
  final void Function(int oldIndex, int newIndex)? onSectionReorder;

  const SitePreviewWidget({
    super.key,
    required this.site,
    required this.products,
    this.business,
    this.editable = false,
    this.onSectionChanged,
    this.onSectionReorder,
  });

  Color get _accent {
    final hex = site.primaryColor;
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!editable) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final section in site.sections) _buildSection(section),
          ],
        ),
      );
    }

    // Editable mode: the same section renderers, but as a reorderable list
    // instead of a plain scrolling Column, so a long press on any section
    // drags it to a new position — this is the exact same interaction
    // Flutter gives ReorderableListView items for free on touch devices
    // (long-press-then-drag), already used the same way by the classic
    // list editor (see EditorCubit.reorderSections / editor_screen.dart).
    return ReorderableListView(
      padding: EdgeInsets.zero,
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorderItem: (oldIndex, newIndex) =>
          onSectionReorder?.call(oldIndex, newIndex),
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (_, __) => Material(
          elevation: 6,
          shadowColor: _accent.withValues(alpha: 0.3),
          child: child,
        ),
      ),
      children: [
        for (final section in site.sections)
          KeyedSubtree(key: ValueKey(section.id), child: _buildSection(section)),
      ],
    );
  }

  Widget _buildSection(SiteSection section) {
    switch (section.type) {
      case SectionType.hero:
        final isEcommerce = site.websiteType == WebsiteType.ecommerce;
        final category = business?.category.label;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: isEcommerce
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_accent, Color.lerp(_accent, Colors.black, 0.25)!],
                  )
                : null,
            color: isEcommerce ? null : _accent.withValues(alpha: 0.12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              if (category != null && category.isNotEmpty) ...[
                Text(
                  category.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: isEcommerce
                        ? Colors.white.withValues(alpha: 0.85)
                        : _accent,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              _field(
                section,
                title: true,
                style: AppTypography.h1.copyWith(
                  color: isEcommerce ? Colors.white : _accent,
                ),
                fallback: 'Bienvenue',
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(
                section,
                title: false,
                style: AppTypography.body.copyWith(
                  color: isEcommerce
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.neutralMid,
                ),
                fallback: 'Decouvrez nos services professionnels.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isEcommerce ? Colors.white : _accent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: (isEcommerce ? Colors.black : _accent)
                          .withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text('Nous contacter',
                    style: AppTypography.button.copyWith(
                      color: isEcommerce ? _accent : Colors.white,
                    )),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );

      case SectionType.about:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(section),
              const SizedBox(height: AppSpacing.sm),
              _field(
                section,
                title: false,
                style: AppTypography.body,
                fallback:
                    'Nous sommes une entreprise dediee a la qualite et au service client.',
              ),
            ],
          ),
        );

      case SectionType.services:
        // Matches the real published output (title + paragraph) so the
        // preview never shows decorative content the visitor won't see.
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: AppColors.neutralLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(section),
              const SizedBox(height: AppSpacing.md),
              if (editable)
                _field(
                  section,
                  title: false,
                  style: AppTypography.body,
                  fallback:
                      'Decrivez vos services pour donner confiance a vos visiteurs.',
                )
              else if (section.content.isNotEmpty)
                Text(section.content, style: AppTypography.body)
              else
                _hint(
                  Icons.miscellaneous_services_outlined,
                  'Decrivez vos services pour donner confiance a vos visiteurs.',
                ),
            ],
          ),
        );

      case SectionType.products:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(section),
              const SizedBox(height: AppSpacing.md),
              if (products.isEmpty)
                _hint(Icons.inventory_2_outlined, 'Aucun produit ajoute')
              else ...[
                if (products.length > 1) ...[
                  Text(
                    'Glissez pour decouvrir',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.neutralMid),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _ProductStack(products: products, accent: _accent),
              ],
            ],
          ),
        );

      case SectionType.contact:
        // The published site pulls phone / WhatsApp / email straight from
        // the business profile (see backend html.builder.ts) — not from
        // this section's free-text content. Mirror that here instead of
        // showing a fabricated phone number that isn't the merchant's.
        final contact = business?.contact;
        final rows = <Widget>[
          if (contact != null && contact.phone.isNotEmpty)
            _contactRow(Icons.phone_outlined, contact.phone),
          if (contact != null && contact.whatsapp.isNotEmpty)
            _contactRow(Icons.chat_outlined, 'WhatsApp : ${contact.whatsapp}'),
          if (contact != null && contact.email.isNotEmpty)
            _contactRow(Icons.email_outlined, contact.email),
        ];
        final showExample = business == null; // template gallery browsing
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: AppColors.neutralLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(section),
              const SizedBox(height: AppSpacing.md),
              if (showExample) ...[
                _contactRow(Icons.phone_outlined, '+226 70 00 00 00'),
                _contactRow(Icons.email_outlined, 'contact@monentreprise.com'),
                _contactRow(Icons.chat_outlined, 'WhatsApp'),
              ] else if (rows.isNotEmpty)
                ...rows
              else
                _hint(
                  Icons.contact_mail_outlined,
                  'Aucune coordonnee renseignee. Ajoutez-les dans votre profil pour que vos clients puissent vous contacter.',
                ),
            ],
          ),
        );

      case SectionType.gallery:
        // There is currently no way for a merchant to attach real gallery
        // photos (unlike products, which do have an upload flow) — so
        // showing 3 permanently-empty gray boxes would look like a broken
        // page to every visitor, forever. Be honest about it instead, the
        // same way the "products"/"services" sections fall back to a plain
        // sentence when there's nothing to show yet.
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(section),
              const SizedBox(height: AppSpacing.md),
              _hint(
                Icons.photo_library_outlined,
                'Galerie photo bientot disponible.',
              ),
            ],
          ),
        );

      case SectionType.testimonials:
        // Never invent a customer quote: a blank testimonial section used to
        // fall back to a fabricated "Fatima K." review, which would present
        // a fake customer opinion as real on an actual visitor-facing site.
        // Only show a quote when the merchant actually wrote one.
        final hasContent = section.content.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(section),
              const SizedBox(height: AppSpacing.md),
              if (editable || hasContent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.neutralLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.format_quote, color: _accent, size: 28),
                      const SizedBox(height: AppSpacing.sm),
                      _field(
                        section,
                        title: false,
                        style: AppTypography.body
                            .copyWith(fontStyle: FontStyle.italic),
                        fallback:
                            'Ajoutez un avis client pour rassurer vos visiteurs.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                _hint(
                  Icons.format_quote_outlined,
                  'Ajoutez un avis client dans "Modifier" pour rassurer vos visiteurs.',
                ),
            ],
          ),
        );

      case SectionType.footer:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: AppColors.neutralDark,
          child: Column(
            children: [
              _field(
                section,
                title: true,
                style:
                    AppTypography.bodySmall.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTypography.caption.copyWith(color: Colors.white38),
                  children: [
                    const TextSpan(text: 'Cree avec '),
                    TextSpan(
                      text: 'NUMBAA',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  /// Section title with a short accent-colored underline, matching the
  /// same "h2::after" treatment used in the real published HTML
  /// (backend/src/publisher/html.builder.ts) so the preview looks like a
  /// faithful miniature of the actual site rather than a rough sketch.
  Widget _sectionHeading(SiteSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(section, title: true, style: AppTypography.h2),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  /// Renders [section]'s title or content (per [title]) as plain read-only
  /// [Text] when [editable] is false — falling back to [fallback] only when
  /// the value is empty, exactly mirroring whatever fallback (or lack of
  /// one) each call site had before this field became editable, so
  /// read-only rendering is unchanged. When [editable] is true, renders an
  /// [_EditableText] instead: tap to edit in place, with [fallback] (or the
  /// section type's label, for an empty title) shown as a ghost hint.
  Widget _field(
    SiteSection section, {
    required bool title,
    required TextStyle style,
    String? fallback,
    TextAlign textAlign = TextAlign.start,
  }) {
    final value = title ? section.title : section.content;
    if (!editable) {
      final display = value.isNotEmpty ? value : (fallback ?? value);
      return Text(display, style: style, textAlign: textAlign);
    }
    return _EditableText(
      text: value,
      placeholder: fallback ?? (title ? section.type.label : ''),
      style: style,
      textAlign: textAlign,
      maxLines: title ? 1 : null,
      onChanged: (v) => onSectionChanged?.call(
        title ? section.copyWith(title: v) : section.copyWith(content: v),
      ),
    );
  }

  /// Honest "nothing here yet" hint — icon + sentence in a soft neutral
  /// card, used consistently wherever a section has no real content to
  /// show instead of fabricating placeholder content for the visitor.
  Widget _hint(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.neutralMid),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.neutralMid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _accent),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.body),
        ],
      ),
    );
  }
}

/// Swipeable "poster" stack for the products section — mirrors the card
/// stack used in the template catalog and the swipeable product cards on
/// the actual published site (see backend/src/publisher/html.builder.ts),
/// so the in-app preview matches what visitors will really see. Wrapped in
/// its own small State so the dot indicator can track the active card
/// without turning [SitePreviewWidget] itself into a StatefulWidget.
class _ProductStack extends StatefulWidget {
  final List<ProductEntity> products;
  final Color accent;
  const _ProductStack({required this.products, required this.accent});

  @override
  State<_ProductStack> createState() => _ProductStackState();
}

class _ProductStackState extends State<_ProductStack> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final products = widget.products;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 320,
          child: CardSwipeStack(
            itemCount: products.length,
            onIndexChanged: (i) => setState(() => _index = i),
            cardBuilder: (context, index) => _ProductPosterCard(
              product: products[index],
              accent: widget.accent,
            ),
          ),
        ),
        if (products.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              products.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? widget.accent : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A single product rendered as a floating poster: a large photo filling
/// the card with the name/price/category legible over a bottom gradient
/// scrim, matching the "grande image, ombre portee, coins arrondis" look
/// used on the real published mini-site.
class _ProductPosterCard extends StatelessWidget {
  final ProductEntity product;
  final Color accent;
  const _ProductPosterCard({required this.product, required this.accent});

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imagePath != null && product.imagePath!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            ResolvedImage(path: product.imagePath!, fit: BoxFit.cover)
          else
            Container(
              color: AppColors.neutralLight,
              child: const Center(
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: AppColors.neutralMid,
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product.category.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Text(
                    product.name,
                    style: AppTypography.h3.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.price.toStringAsFixed(0)} FCFA',
                    style: AppTypography.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap-to-edit inline text used by [SitePreviewWidget] when [editable] is
/// true. Renders as plain [Text] until tapped; tapping swaps it for a
/// borderless, auto-focused [TextField] pre-filled with the current value
/// (selected so typing replaces it outright); losing focus or submitting
/// commits the trimmed result via [onChanged] and returns to read-only
/// display. Kept as its own tiny [StatefulWidget] so [SitePreviewWidget]
/// itself can stay a [StatelessWidget] — the only local state needed
/// anywhere in this file is "is this one field currently being edited?".
class _EditableText extends StatefulWidget {
  final String text;
  final String placeholder;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final ValueChanged<String> onChanged;

  const _EditableText({
    required this.text,
    required this.style,
    required this.onChanged,
    this.placeholder = '',
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  @override
  State<_EditableText> createState() => _EditableTextState();
}

class _EditableTextState extends State<_EditableText> {
  bool _editing = false;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _EditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync if the underlying value changes from outside
    // (e.g. a reorder rebuild) while it isn't the one currently being
    // edited — never stomp on text the user is actively typing.
    if (!_editing && widget.text != _controller.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _editing) _commit();
  }

  void _startEditing() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _commit() {
    if (!mounted) return;
    setState(() => _editing = false);
    final value = _controller.text.trim();
    if (value != widget.text) widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      final isEmpty = widget.text.isEmpty;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startEditing,
        child: Text(
          isEmpty ? widget.placeholder : widget.text,
          style: isEmpty
              ? widget.style.copyWith(
                  color: widget.style.color?.withValues(alpha: 0.45),
                  fontStyle: FontStyle.italic,
                )
              : widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.maxLines != null ? TextOverflow.ellipsis : null,
        ),
      );
    }
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      textInputAction:
          widget.maxLines == 1 ? TextInputAction.done : TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      onSubmitted: widget.maxLines == 1 ? (_) => _commit() : null,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintText: widget.placeholder,
        hintStyle: widget.style.copyWith(
          color: widget.style.color?.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
