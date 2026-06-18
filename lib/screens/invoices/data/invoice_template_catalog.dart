import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

enum InvoiceTemplateIndustry {
  general,
  plumbing,
  electrical,
  hvac,
  carpentry,
  flooring,
  landscaping,
  lawnCare,
  excavation,
  masonry,
  roofing,
  painting,
  cleaning,
  mobileMechanic,
  towing,
  handyman,
}

enum InvoiceTemplateGroup { trades, printerFriendly, flatRate, timeMaterials }

enum InvoiceBillingStyle { flatRate, timeMaterials, either }

enum InvoiceTemplateDelivery { bundled, downloadable }

class InvoiceTemplateDefinition {
  const InvoiceTemplateDefinition({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.description,
    required this.industry,
    required this.hasLogo,
    required this.groups,
    required this.billingStyle,
    required this.accent,
    required this.uiAccent,
    this.previewAssetPath,
    this.firstPageAssetPath,
    this.continuationPageAssetPath,
    this.delivery = InvoiceTemplateDelivery.bundled,
    this.priceCents = 0,
  });

  final String id;
  final String name;
  final String shortLabel;
  final String description;
  final InvoiceTemplateIndustry industry;
  final bool hasLogo;
  final List<InvoiceTemplateGroup> groups;
  final InvoiceBillingStyle billingStyle;
  final PdfColor accent;
  final Color uiAccent;
  final String? previewAssetPath;
  final String? firstPageAssetPath;
  final String? continuationPageAssetPath;
  final InvoiceTemplateDelivery delivery;
  final int priceCents;

  String? assetForPage({required bool continuation}) {
    if (continuation) {
      return continuationPageAssetPath ??
          firstPageAssetPath ??
          previewAssetPath;
    }
    return firstPageAssetPath ?? previewAssetPath;
  }
}

class InvoiceTemplateCatalog {
  const InvoiceTemplateCatalog._();

  static const templates = [
    InvoiceTemplateDefinition(
      id: 'structured-no-logo',
      name: 'Structured No Logo',
      shortLabel: 'Structured',
      description: 'Clean time and materials layout with company text first.',
      industry: InvoiceTemplateIndustry.general,
      hasLogo: false,
      groups: [InvoiceTemplateGroup.timeMaterials],
      billingStyle: InvoiceBillingStyle.timeMaterials,
      accent: PdfColor(0.08, 0.32, 0.55),
      uiAccent: Color(0xFF3EA0E8),
    ),
    InvoiceTemplateDefinition(
      id: 'structured-logo',
      name: 'Structured With Logo',
      shortLabel: 'Logo',
      description: 'Same clean layout with a company logo block.',
      industry: InvoiceTemplateIndustry.general,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.timeMaterials],
      billingStyle: InvoiceBillingStyle.timeMaterials,
      accent: PdfColor(0.08, 0.32, 0.55),
      uiAccent: Color(0xFF3EA0E8),
    ),
    InvoiceTemplateDefinition(
      id: 'plumbing-watermark',
      name: 'Plumbing Copper',
      shortLabel: 'Plumbing',
      description:
          'Detailed plumbing invoice artwork with copper fitting structure.',
      industry: InvoiceTemplateIndustry.plumbing,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.timeMaterials],
      billingStyle: InvoiceBillingStyle.timeMaterials,
      accent: PdfColor(0.72, 0.32, 0.12),
      uiAccent: Color(0xFFC97936),
    ),
    InvoiceTemplateDefinition(
      id: 'plumbing-clean',
      name: 'Plumbing Clean',
      shortLabel: 'Plumbing',
      description:
          'Cleaner plumbing layout with pipe and fixture trade styling.',
      industry: InvoiceTemplateIndustry.plumbing,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.58, 0.30, 0.16),
      uiAccent: Color(0xFFA4663B),
    ),
    InvoiceTemplateDefinition(
      id: 'electrical-blue',
      name: 'Electrical Blue',
      shortLabel: 'Electrical',
      description: 'Electrical service layout with clean blue trade accents.',
      industry: InvoiceTemplateIndustry.electrical,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.timeMaterials],
      billingStyle: InvoiceBillingStyle.timeMaterials,
      accent: PdfColor(0.18, 0.35, 0.66),
      uiAccent: Color(0xFF4F7DDA),
    ),
    InvoiceTemplateDefinition(
      id: 'hvac-cool',
      name: 'HVAC Cool',
      shortLabel: 'HVAC',
      description: 'HVAC layout with cool air and service-equipment styling.',
      industry: InvoiceTemplateIndustry.hvac,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.timeMaterials],
      billingStyle: InvoiceBillingStyle.timeMaterials,
      accent: PdfColor(0.14, 0.51, 0.56),
      uiAccent: Color(0xFF36A5B3),
    ),
    InvoiceTemplateDefinition(
      id: 'carpentry-warm',
      name: 'Carpentry Warm',
      shortLabel: 'Carpentry',
      description: 'Warm wood-inspired layout for carpentry and repairs.',
      industry: InvoiceTemplateIndustry.carpentry,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.54, 0.33, 0.18),
      uiAccent: Color(0xFFB57A48),
    ),
    InvoiceTemplateDefinition(
      id: 'flooring-wood',
      name: 'Flooring Wood',
      shortLabel: 'Flooring',
      description: 'Wood-floor material layout for flooring contractors.',
      industry: InvoiceTemplateIndustry.flooring,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.42, 0.25, 0.13),
      uiAccent: Color(0xFF9A6B3E),
    ),
    InvoiceTemplateDefinition(
      id: 'excavation-field',
      name: 'Excavation Field',
      shortLabel: 'Excavation',
      description: 'Earthwork layout with soft equipment and grade-line marks.',
      industry: InvoiceTemplateIndustry.excavation,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.55, 0.42, 0.20),
      uiAccent: Color(0xFFC7A057),
    ),
    InvoiceTemplateDefinition(
      id: 'earthwork-grade',
      name: 'Earthwork Grade',
      shortLabel: 'Earthwork',
      description: 'Grade-line layout for excavation and site-work invoices.',
      industry: InvoiceTemplateIndustry.excavation,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.45, 0.35, 0.18),
      uiAccent: Color(0xFFAA8A52),
    ),
    InvoiceTemplateDefinition(
      id: 'landscape-soft',
      name: 'Landscape Soft',
      shortLabel: 'Landscape',
      description: 'Green service layout with subtle bed and lawn forms.',
      industry: InvoiceTemplateIndustry.landscaping,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.18, 0.46, 0.24),
      uiAccent: Color(0xFF53B56A),
    ),
    InvoiceTemplateDefinition(
      id: 'landscaping-garden-artwork-v1',
      name: 'Landscape Garden Artwork',
      shortLabel: 'Landscape',
      description:
          'Full-page landscaping invoice artwork with pavers, lawn rows, and garden-bed panels.',
      industry: InvoiceTemplateIndustry.landscaping,
      hasLogo: true,
      groups: [
        InvoiceTemplateGroup.trades,
        InvoiceTemplateGroup.flatRate,
        InvoiceTemplateGroup.timeMaterials,
      ],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.12, 0.32, 0.17),
      uiAccent: Color(0xFF24512C),
    ),
    InvoiceTemplateDefinition(
      id: 'lawn-care',
      name: 'Lawn Care',
      shortLabel: 'Lawn',
      description: 'Lawn and flower-bed layout for mowing and grounds service.',
      industry: InvoiceTemplateIndustry.lawnCare,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.18, 0.49, 0.26),
      uiAccent: Color(0xFF4DA865),
    ),
    InvoiceTemplateDefinition(
      id: 'masonry-block',
      name: 'Masonry Block',
      shortLabel: 'Masonry',
      description: 'Block and mortar layout for masonry repair and installs.',
      industry: InvoiceTemplateIndustry.masonry,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.58, 0.29, 0.22),
      uiAccent: Color(0xFFAD6659),
    ),
    InvoiceTemplateDefinition(
      id: 'roofing-slate',
      name: 'Roofing Slate',
      shortLabel: 'Roofing',
      description: 'Roofing layout with slate and roofline service styling.',
      industry: InvoiceTemplateIndustry.roofing,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.24, 0.30, 0.36),
      uiAccent: Color(0xFF657280),
    ),
    InvoiceTemplateDefinition(
      id: 'painting-pro',
      name: 'Painting Pro',
      shortLabel: 'Painting',
      description: 'Paint and finish layout for painting service invoices.',
      industry: InvoiceTemplateIndustry.painting,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.48, 0.28, 0.66),
      uiAccent: Color(0xFF9668C8),
    ),
    InvoiceTemplateDefinition(
      id: 'cleaning-spark',
      name: 'Cleaning Spark',
      shortLabel: 'Cleaning',
      description: 'Cleaning layout with service and supply-friendly sections.',
      industry: InvoiceTemplateIndustry.cleaning,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.16, 0.50, 0.62),
      uiAccent: Color(0xFF3D9DB8),
    ),
    InvoiceTemplateDefinition(
      id: 'mobile-mechanic',
      name: 'Mobile Mechanic',
      shortLabel: 'Mechanic',
      description: 'Mobile repair layout for parts, labor, and diagnostics.',
      industry: InvoiceTemplateIndustry.mobileMechanic,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.timeMaterials],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.52, 0.16, 0.12),
      uiAccent: Color(0xFFB65042),
    ),
    InvoiceTemplateDefinition(
      id: 'towing-roadside',
      name: 'Towing Roadside',
      shortLabel: 'Towing',
      description: 'Roadside layout for towing and mobile service calls.',
      industry: InvoiceTemplateIndustry.towing,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.flatRate],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.70, 0.45, 0.12),
      uiAccent: Color(0xFFD39A42),
    ),
    InvoiceTemplateDefinition(
      id: 'handyman-tools',
      name: 'Handyman Tools',
      shortLabel: 'Handyman',
      description: 'General service layout for mixed repair work.',
      industry: InvoiceTemplateIndustry.handyman,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.trades, InvoiceTemplateGroup.timeMaterials],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.26, 0.38, 0.48),
      uiAccent: Color(0xFF587C91),
    ),
    InvoiceTemplateDefinition(
      id: 'geometric-gold',
      name: 'Generic Gold',
      shortLabel: 'Gold',
      description: 'General-purpose invoice with polished gold geometry.',
      industry: InvoiceTemplateIndustry.general,
      hasLogo: true,
      groups: [
        InvoiceTemplateGroup.printerFriendly,
        InvoiceTemplateGroup.flatRate,
      ],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.62, 0.42, 0.14),
      uiAccent: Color(0xFFC59A46),
    ),
    InvoiceTemplateDefinition(
      id: 'geometric-slate',
      name: 'Generic Slate',
      shortLabel: 'Slate',
      description: 'General-purpose invoice with restrained slate styling.',
      industry: InvoiceTemplateIndustry.general,
      hasLogo: true,
      groups: [
        InvoiceTemplateGroup.printerFriendly,
        InvoiceTemplateGroup.timeMaterials,
      ],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.22, 0.27, 0.33),
      uiAccent: Color(0xFF637181),
    ),
    InvoiceTemplateDefinition(
      id: 'printer-logo',
      name: 'Printer With Logo',
      shortLabel: 'Printer',
      description: 'Low-ink printable layout with company logo space.',
      industry: InvoiceTemplateIndustry.general,
      hasLogo: true,
      groups: [InvoiceTemplateGroup.printerFriendly],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.12, 0.12, 0.12),
      uiAccent: Color(0xFFE4E8EA),
    ),
    InvoiceTemplateDefinition(
      id: 'printer-friendly',
      name: 'Printer Friendly',
      shortLabel: 'Printer',
      description: 'Low-ink layout for printing, signing, and filing.',
      industry: InvoiceTemplateIndustry.general,
      hasLogo: false,
      groups: [
        InvoiceTemplateGroup.printerFriendly,
        InvoiceTemplateGroup.flatRate,
        InvoiceTemplateGroup.timeMaterials,
      ],
      billingStyle: InvoiceBillingStyle.either,
      accent: PdfColor(0.12, 0.12, 0.12),
      uiAccent: Color(0xFFE4E8EA),
    ),
  ];

  static InvoiceTemplateDefinition byId(String id) {
    return templates.firstWhere(
      (template) => template.id == id,
      orElse: () => templates.first,
    );
  }
}
