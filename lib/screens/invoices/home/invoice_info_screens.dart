import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/media/app_media_asset.dart';
import '../../../shared/media/app_media_asset_store.dart';
import '../data/invoice_ledger_models.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/record_form_fields.dart';

class InvoiceCompanyInfoScreen extends StatelessWidget {
  const InvoiceCompanyInfoScreen({this.initial, super.key});

  final InvoicePartySnapshot? initial;

  @override
  Widget build(BuildContext context) {
    return _InvoiceInfoFormScreen(
      title: 'My Info',
      description:
          'Fill out your company information here. This is what appears on invoices and estimates you create.',
      nameLabel: 'Business Name',
      notesLabel: 'Company Notes',
      requireName: true,
      initial: initial,
    );
  }
}

class InvoiceClientInfoScreen extends StatelessWidget {
  const InvoiceClientInfoScreen({this.initial, super.key});

  final InvoicePartySnapshot? initial;

  @override
  Widget build(BuildContext context) {
    return _InvoiceInfoFormScreen(
      title: 'Saved Clients',
      description:
          'Add or update saved client information here. These details can be reused on future invoices, estimates, and customer records.',
      nameLabel: 'Client Name',
      notesLabel: 'Client Notes',
      requireName: true,
      initial: initial,
    );
  }
}

class InvoicePaymentScreen extends StatefulWidget {
  const InvoicePaymentScreen({super.key});

  @override
  State<InvoicePaymentScreen> createState() => _InvoicePaymentScreenState();
}

class _InvoicePaymentScreenState extends State<InvoicePaymentScreen> {
  final _amount = TextEditingController();
  final _source = TextEditingController();
  final _method = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _source.dispose();
    _method.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.invoices,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        children: [
          const AppScreenHeader(title: 'Payments'),
          const SizedBox(height: 8),
          const GlobalOdometerHeader(section: AppSection.invoices),
          const SizedBox(height: 8),
          const _InvoiceFormIntro(
            text:
                'Record money received here. Payments can be linked to invoices, jobs, dashboard income, or quick records later.',
          ),
          const SizedBox(height: 10),
          RecordFormPanel(
            children: [
              RecordTextField(
                label: 'Payment Amount',
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              RecordTextField(
                label: 'Payment Source',
                hintText: 'Client, platform, cash job',
                controller: _source,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              RecordTextField(
                label: 'Payment Method',
                hintText: 'Cash, card, check, transfer',
                controller: _method,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              RecordTextField(
                label: 'Payment Notes',
                controller: _notes,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 12),
              _SaveFormButton(onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceInfoFormScreen extends StatefulWidget {
  const _InvoiceInfoFormScreen({
    required this.title,
    required this.description,
    required this.nameLabel,
    required this.notesLabel,
    required this.requireName,
    this.initial,
  });

  final String title;
  final String description;
  final String nameLabel;
  final String notesLabel;
  final bool requireName;
  final InvoicePartySnapshot? initial;

  @override
  State<_InvoiceInfoFormScreen> createState() => _InvoiceInfoFormScreenState();
}

class _InvoiceInfoFormScreenState extends State<_InvoiceInfoFormScreen> {
  final _name = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _phones = <_EditablePhoneNumber>[];
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _notes = TextEditingController();
  var _businessCategory = _businessCategories.first;
  String _logoLabel = 'No logo selected';
  String _logoPath = '';
  AppMediaAsset _logoAsset = AppMediaAsset.empty();

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _name.text = widget.title == 'My Info'
        ? initial.companyName
        : initial.displayName;
    _street.text = initial.street;
    _city.text = initial.city;
    _state.text = initial.state;
    _zip.text = initial.postalCode;
    final initialPhones = initial.phones
        .where((entry) => entry.hasNumber)
        .toList(growable: false);
    if (initialPhones.isNotEmpty) {
      _phones.addAll(
        initialPhones.map(
          (entry) => _EditablePhoneNumber(
            type: _normalizedPhoneType(entry.type),
            number: entry.number,
          ),
        ),
      );
    } else if (initial.phone.trim().isNotEmpty) {
      _phones.add(
        _EditablePhoneNumber(type: 'Business', number: initial.phone),
      );
    }
    _email.text = initial.email;
    _website.text = initial.website;
    _notes.text = initial.notes;
    _logoPath = initial.logoPath;
    _logoAsset = initial.logoAsset.hasFile
        ? initial.logoAsset
        : _logoPath.trim().isEmpty
        ? AppMediaAsset.empty()
        : AppMediaAsset.empty().copyWith(path: _logoPath);
    if (_logoAsset.hasFile) {
      _logoPath = _logoAsset.path;
      _logoLabel = _fileName(_logoPath);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    for (final phone in _phones) {
      phone.dispose();
    }
    _email.dispose();
    _website.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.invoices,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        children: [
          AppScreenHeader(title: widget.title),
          const SizedBox(height: 8),
          const GlobalOdometerHeader(section: AppSection.invoices),
          const SizedBox(height: 8),
          _InvoiceFormIntro(text: widget.description),
          const SizedBox(height: 10),
          RecordFormPanel(
            children: [
              if (widget.title == 'My Info') ...[
                RecordDropdownField<String>(
                  label: 'Business Category',
                  value: _businessCategory,
                  items: _businessCategories,
                  itemLabel: (value) => value,
                  onChanged: (value) {
                    setState(() => _businessCategory = value);
                  },
                ),
                const SizedBox(height: 10),
                _LogoImportPanel(
                  logoLabel: _logoLabel,
                  onPhotoLibrary: () => _pickLogoFromGallery(),
                  onCamera: () => _pickLogoFromCamera(),
                  onFile: () => _pickLogoFromFile(),
                ),
                const SizedBox(height: 10),
              ],
              RecordTextField(
                label: widget.nameLabel,
                helperText: widget.requireName ? 'Required' : null,
                controller: _name,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              RecordTextField(
                label: 'Street Address',
                hintText: '192 Main Street',
                controller: _street,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              RecordTextField(
                label: 'City',
                controller: _city,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: RecordDropdownField<String>(
                      label: 'State',
                      value: _state.text,
                      items: _usStates,
                      itemLabel: (value) =>
                          value.isEmpty ? 'Select state' : value,
                      onChanged: (value) => setState(() => _state.text = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: RecordTextField(
                      label: 'ZIP Code',
                      controller: _zip,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PhoneNumbersPanel(
                phones: _phones,
                onAdd: _addPhoneNumber,
                onRemove: _removePhoneNumber,
                onTypeChanged: _changePhoneType,
              ),
              const SizedBox(height: 10),
              RecordTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              RecordTextField(
                label: 'Website',
                controller: _website,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              RecordTextField(
                label: widget.notesLabel,
                controller: _notes,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 12),
              _SaveFormButton(onPressed: _save),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogoFromGallery() async {
    final approved = await _confirmLogoImport(
      title: 'Choose Logo Photo',
      message:
          'Maintaniac only receives the logo image you choose. It does not scan or import your photo library.',
      actionLabel: 'Choose Logo Photo',
    );
    if (!approved || !mounted) return;
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;
      final asset = await AppMediaAssetStore.instance.importCompanyLogo(
        sourcePath: image.path,
        originalFileName: _fileName(image.path),
      );
      if (!mounted) return;
      setState(() {
        _logoAsset = asset;
        _logoPath = asset.path;
        _logoLabel = asset.displayName.trim().isEmpty
            ? _fileName(asset.path)
            : asset.displayName;
      });
    } on AppMediaAssetException catch (error) {
      _showLogoError(error.message);
    } catch (_) {
      _showLogoError('The photo library could not be opened.');
    }
  }

  Future<void> _pickLogoFromCamera() async {
    final approved = await _confirmLogoImport(
      title: 'Take Logo Photo',
      message:
          'Maintaniac opens the camera only after you choose to take a company logo photo.',
      actionLabel: 'Open Camera',
    );
    if (!approved || !mounted) return;
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null || !mounted) return;
      final asset = await AppMediaAssetStore.instance.importCompanyLogo(
        sourcePath: image.path,
        originalFileName: _fileName(image.path),
      );
      if (!mounted) return;
      setState(() {
        _logoAsset = asset;
        _logoPath = asset.path;
        _logoLabel = asset.displayName.trim().isEmpty
            ? _fileName(asset.path)
            : asset.displayName;
      });
    } on AppMediaAssetException catch (error) {
      _showLogoError(error.message);
    } catch (_) {
      _showLogoError('The camera could not be opened.');
    }
  }

  Future<void> _pickLogoFromFile() async {
    final approved = await _confirmLogoImport(
      title: 'Pick Logo File',
      message:
          'Maintaniac only receives the file you choose. PNG and JPG logo files are supported here.',
      actionLabel: 'Pick Logo File',
    );
    if (!approved || !mounted) return;
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg'],
      );
      final file = picked?.files.single;
      if (file == null || !mounted) return;
      final sourcePath = file.path;
      if (sourcePath == null || sourcePath.trim().isEmpty) {
        _showLogoError('That logo file could not be opened.');
        return;
      }
      final asset = await AppMediaAssetStore.instance.importCompanyLogo(
        sourcePath: sourcePath,
        originalFileName: file.name,
      );
      if (!mounted) return;
      setState(() {
        _logoAsset = asset;
        _logoPath = asset.path;
        _logoLabel = asset.displayName.trim().isEmpty
            ? _fileName(asset.path)
            : asset.displayName;
      });
    } on AppMediaAssetException catch (error) {
      _showLogoError(error.message);
    } catch (_) {
      _showLogoError('The file picker could not be opened.');
    }
  }

  Future<bool> _confirmLogoImport({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final approved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _LogoAccessSheet(
          title: title,
          message: message,
          actionLabel: actionLabel,
        );
      },
    );
    return approved == true;
  }

  void _showLogoError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    if (widget.requireName && _name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.nameLabel} is required.')),
      );
      return;
    }
    final trimmedName = _name.text.trim();
    final phoneEntries = _phones
        .map(
          (entry) => InvoicePhoneNumber(
            type: entry.type,
            number: entry.controller.text.trim(),
          ),
        )
        .where((entry) => entry.hasNumber)
        .toList(growable: false);
    Navigator.of(context).pop(
      InvoicePartySnapshot(
        displayName: widget.title == 'My Info' ? '' : trimmedName,
        companyName: widget.title == 'My Info' ? trimmedName : '',
        street: _street.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        postalCode: _zip.text.trim(),
        phone: phoneEntries.isEmpty ? '' : phoneEntries.first.number,
        phones: phoneEntries,
        email: _email.text.trim(),
        website: _website.text.trim(),
        notes: _notes.text.trim(),
        logoPath: widget.title == 'My Info' ? _logoPath : '',
        logoAsset: widget.title == 'My Info'
            ? _logoAsset
            : AppMediaAsset.empty(),
      ),
    );
  }

  void _addPhoneNumber() {
    setState(() => _phones.add(_EditablePhoneNumber()));
  }

  void _removePhoneNumber(_EditablePhoneNumber phone) {
    setState(() {
      _phones.remove(phone);
      phone.dispose();
    });
  }

  void _changePhoneType(_EditablePhoneNumber phone, String value) {
    setState(() => phone.type = value);
  }
}

class _EditablePhoneNumber {
  _EditablePhoneNumber({this.type = 'Mobile', String number = ''})
    : controller = TextEditingController(text: number);

  String type;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

class _LogoAccessSheet extends StatelessWidget {
  const _LogoAccessSheet({
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final String title;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFD4DDE1),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(actionLabel),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneNumbersPanel extends StatelessWidget {
  const _PhoneNumbersPanel({
    required this.phones,
    required this.onAdd,
    required this.onRemove,
    required this.onTypeChanged,
  });

  final List<_EditablePhoneNumber> phones;
  final VoidCallback onAdd;
  final ValueChanged<_EditablePhoneNumber> onRemove;
  final void Function(_EditablePhoneNumber phone, String value) onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF141A1D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF667178)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Phone Numbers',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_call, size: 18),
                  label: const Text('Add Phone Number'),
                ),
              ],
            ),
            if (phones.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Add mobile, office, home, or business numbers if you want '
                'them printed on invoices.',
                style: TextStyle(
                  color: Color(0xFFD4DDE1),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ] else
              for (final phone in phones) ...[
                const SizedBox(height: 10),
                _PhoneNumberRow(
                  phone: phone,
                  onRemove: () => onRemove(phone),
                  onTypeChanged: (value) => onTypeChanged(phone, value),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _PhoneNumberRow extends StatelessWidget {
  const _PhoneNumberRow({
    required this.phone,
    required this.onRemove,
    required this.onTypeChanged,
  });

  final _EditablePhoneNumber phone;
  final VoidCallback onRemove;
  final ValueChanged<String> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: RecordDropdownField<String>(
            label: 'Phone Type',
            value: phone.type,
            items: _phoneTypes,
            itemLabel: (value) => value,
            onChanged: onTypeChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: RecordTextField(
            label: 'Phone Number',
            hintText: '(555) 123-4567',
            controller: phone.controller,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _UsPhoneNumberFormatter(),
            ],
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Remove phone number',
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }
}

class _LogoImportPanel extends StatelessWidget {
  const _LogoImportPanel({
    required this.logoLabel,
    required this.onPhotoLibrary,
    required this.onCamera,
    required this.onFile,
  });

  final String logoLabel;
  final VoidCallback onPhotoLibrary;
  final VoidCallback onCamera;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF141A1D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF667178)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.business_center_rounded,
                  color: Color(0xFFFFD166),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    logoLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LogoButton(
                  label: 'Import Photo',
                  icon: Icons.photo_library_rounded,
                  onPressed: onPhotoLibrary,
                ),
                _LogoButton(
                  label: 'Take Photo',
                  icon: Icons.photo_camera_rounded,
                  onPressed: onCamera,
                ),
                _LogoButton(
                  label: 'Pick File',
                  icon: Icons.attach_file_rounded,
                  onPressed: onFile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoButton extends StatelessWidget {
  const _LogoButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _InvoiceFormIntro extends StatelessWidget {
  const _InvoiceFormIntro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFD4DDE1),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.18,
      ),
    );
  }
}

class _SaveFormButton extends StatelessWidget {
  const _SaveFormButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: const Text('Save And Continue'),
    );
  }
}

class _UsPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 10 ? digits.substring(0, 10) : digits;
    final formatted = _format(limited);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length <= 3) return '(${digits.padRight(0)}';
    if (digits.length <= 6) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    }
    return '(${digits.substring(0, 3)}) '
        '${digits.substring(3, 6)}-${digits.substring(6)}';
  }
}

const _usStates = <String>[
  '',
  'AL',
  'AK',
  'AZ',
  'AR',
  'CA',
  'CO',
  'CT',
  'DE',
  'DC',
  'FL',
  'GA',
  'HI',
  'ID',
  'IL',
  'IN',
  'IA',
  'KS',
  'KY',
  'LA',
  'ME',
  'MD',
  'MA',
  'MI',
  'MN',
  'MS',
  'MO',
  'MT',
  'NE',
  'NV',
  'NH',
  'NJ',
  'NM',
  'NY',
  'NC',
  'ND',
  'OH',
  'OK',
  'OR',
  'PA',
  'RI',
  'SC',
  'SD',
  'TN',
  'TX',
  'UT',
  'VT',
  'VA',
  'WA',
  'WV',
  'WI',
  'WY',
];

const _businessCategories = <String>[
  'Contractor / Service Business',
  'Plumbing',
  'Electrical',
  'HVAC',
  'Carpentry',
  'Landscaping / Lawn Care',
  'Excavation / Dirt Work',
  'Mobile Mechanic',
  'Gig Driver / Delivery',
  'Other',
];

const _phoneTypes = <String>[
  'Mobile',
  'Office',
  'Business',
  'Home',
  'After Hours',
  'Fax',
];

String _normalizedPhoneType(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Mobile';
  for (final type in _phoneTypes) {
    if (type.toLowerCase() == trimmed.toLowerCase()) return type;
  }
  return 'Business';
}

String _fileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  final slash = normalized.lastIndexOf('/');
  if (slash == -1) return normalized;
  return normalized.substring(slash + 1);
}
