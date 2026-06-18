import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:printing/printing.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/industrial_panel_surface.dart';
import '../data/invoice_pdf_preview_factory.dart';
import '../data/invoice_template_catalog.dart';
import 'invoice_template_preview_screen.dart';

class InvoiceTemplateScreen extends StatefulWidget {
  const InvoiceTemplateScreen({
    this.selectionMode = false,
    this.selectedTemplateId,
    super.key,
  });

  final bool selectionMode;
  final String? selectedTemplateId;

  @override
  State<InvoiceTemplateScreen> createState() => _InvoiceTemplateScreenState();
}

class _InvoiceTemplateScreenState extends State<InvoiceTemplateScreen> {
  var _group = InvoiceTemplateGroup.trades;
  var _selectedTrade = InvoiceTemplateIndustry.landscaping;

  @override
  void initState() {
    super.initState();
    final selectedTemplateId = widget.selectedTemplateId;
    if (selectedTemplateId == null || selectedTemplateId.trim().isEmpty) {
      return;
    }
    final selectedTemplate = InvoiceTemplateCatalog.byId(selectedTemplateId);
    if (selectedTemplate.industry != InvoiceTemplateIndustry.general) {
      _selectedTrade = selectedTemplate.industry;
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = _visibleTemplates();
    return AppScreenShell(
      section: AppSection.invoices,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        children: [
          const AppBackButton(),
          const SizedBox(height: 8),
          AppScreenHeader(
            title: widget.selectionMode
                ? 'Choose Invoice Template'
                : 'Select Invoice Template',
          ),
          const SizedBox(height: 10),
          _TemplateModeStrip(
            selected: _group,
            onSelected: (group) => setState(() => _group = group),
          ),
          const SizedBox(height: 10),
          if (_group == InvoiceTemplateGroup.trades) ...[
            _TradeTemplateFilter(
              selected: _selectedTrade,
              onChanged: (trade) => setState(() => _selectedTrade = trade),
            ),
            const SizedBox(height: 10),
          ],
          if (templates.isEmpty)
            _TemplateEmptyState(trade: _selectedTrade)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: templates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: .72,
              ),
              itemBuilder: (context, index) {
                final template = templates[index];
                return _TemplatePreviewCard(
                  template: template,
                  selected: widget.selectedTemplateId == template.id,
                  selectionMode: widget.selectionMode,
                  onTap: () => _openTemplate(context, template),
                );
              },
            ),
        ],
      ),
    );
  }

  List<InvoiceTemplateDefinition> _visibleTemplates() {
    return InvoiceTemplateCatalog.templates
        .where((template) {
          if (!template.groups.contains(_group)) return false;
          if (_group != InvoiceTemplateGroup.trades) {
            return template.industry == InvoiceTemplateIndustry.general ||
                template.previewAssetPath != null;
          }
          return template.industry == _selectedTrade;
        })
        .toList(growable: false);
  }

  void _openTemplate(BuildContext context, InvoiceTemplateDefinition template) {
    if (widget.selectionMode) {
      Navigator.of(context).push(
        appNativeRoute<void>(
          context,
          _TemplateSelectionPreviewScreen(template: template),
        ),
      );
      return;
    }
    final documentFuture = const InvoicePdfPreviewFactory()
        .buildTemplateSamplePreview(template: template);
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        InvoiceTemplatePreviewScreen(
          title: template.name,
          documentFuture: documentFuture,
        ),
      ),
    );
  }
}

class _TradeTemplateFilter extends StatelessWidget {
  const _TradeTemplateFilter({required this.selected, required this.onChanged});

  final InvoiceTemplateIndustry selected;
  final ValueChanged<InvoiceTemplateIndustry> onChanged;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InvoiceTemplateIndustry>(
          value: selected,
          isExpanded: true,
          dropdownColor: const Color(0xFF141A1D),
          iconEnabledColor: const Color(0xFFFFD166),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          items: [
            for (final trade in _tradeIndustries)
              DropdownMenuItem(
                value: trade,
                child: Text(_industryLabel(trade)),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _TemplateEmptyState extends StatelessWidget {
  const _TemplateEmptyState({required this.trade});

  final InvoiceTemplateIndustry trade;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Text(
        'No bundled ${_industryLabel(trade)} artwork templates yet. '
        'Cloud template downloads will live here once the Firebase template '
        'library is wired in.',
        style: const TextStyle(
          color: Color(0xFFD4DDE1),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
      ),
    );
  }
}

class _TemplateModeStrip extends StatelessWidget {
  const _TemplateModeStrip({required this.selected, required this.onSelected});

  final InvoiceTemplateGroup selected;
  final ValueChanged<InvoiceTemplateGroup> onSelected;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final group in InvoiceTemplateGroup.values)
            _TemplateModePill(
              label: _groupLabel(group),
              active: selected == group,
              onTap: () => onSelected(group),
            ),
        ],
      ),
    );
  }
}

class _TemplateModePill extends StatelessWidget {
  const _TemplateModePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 38, minWidth: 128),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF12384F) : const Color(0xFF101416),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: active ? const Color(0xFFFFD166) : const Color(0xFF6F7A80),
            width: active ? 1.7 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

String _groupLabel(InvoiceTemplateGroup group) {
  return switch (group) {
    InvoiceTemplateGroup.trades => 'Trades',
    InvoiceTemplateGroup.printerFriendly => 'Printer Friendly',
    InvoiceTemplateGroup.flatRate => 'Flat Rate',
    InvoiceTemplateGroup.timeMaterials => 'Time & Materials',
  };
}

const _tradeIndustries = <InvoiceTemplateIndustry>[
  InvoiceTemplateIndustry.plumbing,
  InvoiceTemplateIndustry.electrical,
  InvoiceTemplateIndustry.hvac,
  InvoiceTemplateIndustry.carpentry,
  InvoiceTemplateIndustry.flooring,
  InvoiceTemplateIndustry.landscaping,
  InvoiceTemplateIndustry.lawnCare,
  InvoiceTemplateIndustry.excavation,
  InvoiceTemplateIndustry.masonry,
  InvoiceTemplateIndustry.roofing,
  InvoiceTemplateIndustry.painting,
  InvoiceTemplateIndustry.cleaning,
  InvoiceTemplateIndustry.mobileMechanic,
  InvoiceTemplateIndustry.towing,
  InvoiceTemplateIndustry.handyman,
];

String _industryLabel(InvoiceTemplateIndustry industry) {
  return switch (industry) {
    InvoiceTemplateIndustry.general => 'General',
    InvoiceTemplateIndustry.plumbing => 'Plumbing',
    InvoiceTemplateIndustry.electrical => 'Electrical',
    InvoiceTemplateIndustry.hvac => 'HVAC',
    InvoiceTemplateIndustry.carpentry => 'Carpentry',
    InvoiceTemplateIndustry.flooring => 'Flooring',
    InvoiceTemplateIndustry.landscaping => 'Landscaping',
    InvoiceTemplateIndustry.lawnCare => 'Lawn Care',
    InvoiceTemplateIndustry.excavation => 'Excavation',
    InvoiceTemplateIndustry.masonry => 'Masonry',
    InvoiceTemplateIndustry.roofing => 'Roofing',
    InvoiceTemplateIndustry.painting => 'Painting',
    InvoiceTemplateIndustry.cleaning => 'Cleaning',
    InvoiceTemplateIndustry.mobileMechanic => 'Mobile Mechanic',
    InvoiceTemplateIndustry.towing => 'Towing',
    InvoiceTemplateIndustry.handyman => 'Handyman',
  };
}

class _TemplatePreviewCard extends StatelessWidget {
  const _TemplatePreviewCard({
    required this.template,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
  });

  final InvoiceTemplateDefinition template;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Preview ${template.name} invoice template',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: IndustrialPanelSurface(
          dark: true,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _MiniInvoicePreview(template: template)),
              const SizedBox(height: 7),
              if (selected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF6BE58D),
                  size: 18,
                ),
                const SizedBox(height: 3),
              ],
              Text(
                template.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                selectionMode
                    ? 'Tap to use this template'
                    : template.hasLogo
                    ? 'With logo space'
                    : 'No logo space',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInvoicePreview extends StatelessWidget {
  const _MiniInvoicePreview({required this.template});

  final InvoiceTemplateDefinition template;

  @override
  Widget build(BuildContext context) {
    final assetPath = template.previewAssetPath;
    if (assetPath != null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF101416)),
        ),
        clipBehavior: Clip.antiAlias,
        child: _TemplateAssetImage(assetPath: assetPath, fit: BoxFit.cover),
      );
    }
    return FutureBuilder<Uint8List?>(
      future: _TemplateThumbnailCache.thumbnailFor(template),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return _TemplateThumbnailFallback(template: template);
        }
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF101416)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(bytes, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _TemplateThumbnailFallback extends StatelessWidget {
  const _TemplateThumbnailFallback({required this.template});

  final InvoiceTemplateDefinition template;

  @override
  Widget build(BuildContext context) {
    final accent = template.uiAccent;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF101416)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _MiniBackground(template: template)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (template.hasLogo) ...[
                    Container(width: 22, height: 22, color: accent),
                    const SizedBox(width: 5),
                  ],
                  Expanded(child: _MiniLine(widthFactor: .8, color: accent)),
                  const SizedBox(width: 5),
                  _MiniLine(widthFactor: .22, color: accent),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Expanded(child: _MiniLine(widthFactor: .85)),
                  SizedBox(width: 10),
                  Expanded(child: _MiniLine(widthFactor: .75)),
                ],
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < 5; index++) ...[
                _MiniLine(widthFactor: index.isEven ? .95 : .8),
                const SizedBox(height: 5),
              ],
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: _MiniLine(widthFactor: .38, color: accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateThumbnailCache {
  _TemplateThumbnailCache._();

  static final _cache = <String, Future<Uint8List?>>{};

  static Future<Uint8List?> thumbnailFor(InvoiceTemplateDefinition template) {
    return _cache.putIfAbsent(template.id, () => _render(template));
  }

  static Future<Uint8List?> _render(InvoiceTemplateDefinition template) async {
    try {
      final document = await const InvoicePdfPreviewFactory()
          .buildTemplateSamplePreview(template: template);
      final pages = Printing.raster(document.bytes, pages: const [0], dpi: 42);
      await for (final page in pages) {
        return page.toPng();
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

class _MiniBackground extends StatelessWidget {
  const _MiniBackground({required this.template});

  final InvoiceTemplateDefinition template;

  @override
  Widget build(BuildContext context) {
    final color = template.uiAccent.withValues(alpha: .14);
    final label = switch (template.industry) {
      InvoiceTemplateIndustry.plumbing => 'PIPE  TEE  VALVE',
      InvoiceTemplateIndustry.electrical => 'WIRE  BREAKER  OUTLET',
      InvoiceTemplateIndustry.hvac => 'AIR  FILTER  DUCT',
      InvoiceTemplateIndustry.carpentry => 'LUMBER  TRIM  FASTENER',
      InvoiceTemplateIndustry.flooring => 'PLANK  TRIM  UNDERLAY',
      InvoiceTemplateIndustry.excavation => 'GRADE  TRENCH  EQUIP',
      InvoiceTemplateIndustry.landscaping => 'LAWN  BED  SERVICE',
      InvoiceTemplateIndustry.lawnCare => 'MOW  EDGE  SEED',
      InvoiceTemplateIndustry.masonry => 'BLOCK  BRICK  MORTAR',
      InvoiceTemplateIndustry.roofing => 'ROOF  FLASHING  SHINGLE',
      InvoiceTemplateIndustry.painting => 'PAINT  WALL  TRIM',
      InvoiceTemplateIndustry.cleaning => 'CLEAN  DETAIL  SERVICE',
      InvoiceTemplateIndustry.mobileMechanic => 'PARTS  LABOR  REPAIR',
      InvoiceTemplateIndustry.towing => 'TOW  ROADSIDE  SERVICE',
      InvoiceTemplateIndustry.handyman => 'TOOLS  REPAIR  SERVICE',
      InvoiceTemplateIndustry.general => '',
    };
    if (label.isEmpty) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Container(width: 54, height: 54, color: color),
      );
    }
    return Center(
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TemplateSelectionPreviewScreen extends StatelessWidget {
  const _TemplateSelectionPreviewScreen({required this.template});

  final InvoiceTemplateDefinition template;

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.invoices,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: [
                const AppBackButton(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: IndustrialPanelSurface(
                dark: true,
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _TemplateLargePreview(template: template),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final documentFuture = const InvoicePdfPreviewFactory()
                          .buildTemplateSamplePreview(template: template);
                      Navigator.of(context).push(
                        appNativeRoute<void>(
                          context,
                          InvoiceTemplatePreviewScreen(
                            title: template.name,
                            documentFuture: documentFuture,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Preview PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                        ..pop()
                        ..pop(template.id);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Use This Template'),
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

class _TemplateLargePreview extends StatelessWidget {
  const _TemplateLargePreview({required this.template});

  final InvoiceTemplateDefinition template;

  @override
  Widget build(BuildContext context) {
    final assetPath = template.previewAssetPath;
    if (assetPath != null) {
      return ColoredBox(
        color: const Color(0xFFF7F7F2),
        child: InteractiveViewer(
          minScale: .75,
          maxScale: 4,
          child: Center(
            child: _TemplateAssetImage(
              assetPath: assetPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }
    return _TemplateThumbnailFallback(template: template);
  }
}

class _TemplateAssetImage extends StatelessWidget {
  const _TemplateAssetImage({required this.assetPath, required this.fit});

  final String assetPath;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (assetPath.endsWith('.svg')) {
      return SvgPicture.asset(assetPath, fit: fit);
    }
    return Image.asset(assetPath, fit: fit);
  }
}

class _MiniLine extends StatelessWidget {
  const _MiniLine({this.widthFactor = 1, this.color = const Color(0xFF5E686D)});

  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 88.0;
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: boundedWidth * widthFactor,
            child: Container(height: 5, color: color.withValues(alpha: .75)),
          ),
        );
      },
    );
  }
}
