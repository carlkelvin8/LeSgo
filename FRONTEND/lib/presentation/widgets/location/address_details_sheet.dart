import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lesgo/core/theme/app_colors.dart';
import '../../../core/utils/ph_address.dart';

const _brand = Color(0xFF5F2D82);

/// Lets the customer confirm and complete the address for a pinned spot: block
/// and lot, street, subdivision or village, barangay, city, province and ZIP.
/// Whatever the map could work out is pre-filled; the rest is typed here, so a
/// pin in a big city still ends up as an exact address the rider can find.
class AddressDetailsSheet extends StatefulWidget {
  const AddressDetailsSheet({
    super.key,
    required this.initial,
    this.title = 'Confirm your exact address',
  });

  final PhAddress initial;
  final String title;

  /// Returns the confirmed address, or null if the customer backs out.
  static Future<PhAddress?> show(
    BuildContext context, {
    required PhAddress initial,
    String title = 'Confirm your exact address',
  }) {
    return showModalBottomSheet<PhAddress>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressDetailsSheet(initial: initial, title: title),
    );
  }

  @override
  State<AddressDetailsSheet> createState() => _AddressDetailsSheetState();
}

class _AddressDetailsSheetState extends State<AddressDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;

  static const _fields = [
    'block',
    'lot',
    'houseNumber',
    'street',
    'subdivision',
    'barangay',
    'city',
    'province',
    'zip',
    'landmark',
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    final values = {
      'block': i.block,
      'lot': i.lot,
      'houseNumber': i.houseNumber,
      'street': i.street,
      'subdivision': i.subdivision,
      'barangay': i.barangay,
      'city': i.city,
      'province': i.province,
      'zip': i.zip,
      'landmark': i.landmark,
    };
    _c = {
      for (final f in _fields)
        f: TextEditingController(text: values[f])..addListener(_refresh),
    };
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _t(String f) => _c[f]!.text.trim();

  PhAddress get _current => PhAddress(
    block: _t('block'),
    lot: _t('lot'),
    houseNumber: _t('houseNumber'),
    street: _t('street'),
    subdivision: _t('subdivision'),
    barangay: _t('barangay'),
    city: _t('city'),
    province: _t('province'),
    zip: _t('zip'),
    landmark: _t('landmark'),
  );

  /// True when the customer has not yet said where in the city this is.
  bool get _needsMore {
    final a = _current;
    return a.block.isEmpty &&
        a.lot.isEmpty &&
        a.houseNumber.isEmpty &&
        a.street.isEmpty &&
        a.subdivision.isEmpty;
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.pop(context, _current);
  }

  Widget _field(
    String key,
    String label, {
    String? hint,
    TextInputType? type,
    TextCapitalization caps = TextCapitalization.words,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextFormField(
      controller: _c[key],
      keyboardType: type,
      textCapitalization: caps,
      textInputAction: action,
      inputFormatters: formatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: AppColors.surface(context, const Color(0xFFF6F2FA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _brand);
    final preview = _current.full;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(context, Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check what we found for your pin and add your block, lot and street so the rider can find you.',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.foreground(context, Colors.grey[600]!),
                  ),
                ),
                if (_needsMore) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFFB26A00),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'We could only find the city for this pin. Please add your block/lot, street or subdivision.',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 12.5,
                              height: 1.35,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'block',
                        'Block',
                        hint: 'e.g. 14',
                        type: TextInputType.text,
                        caps: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        'lot',
                        'Lot',
                        hint: 'e.g. 9',
                        type: TextInputType.text,
                        caps: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        'houseNumber',
                        'House / Unit',
                        hint: 'No.',
                        type: TextInputType.text,
                        caps: TextCapitalization.characters,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _field('street', 'Street', hint: 'e.g. Mahogany Street'),
                const SizedBox(height: 10),
                _field(
                  'subdivision',
                  'Subdivision / Village / Building',
                  hint: 'e.g. Francisco Homes, Phase 3',
                ),
                const SizedBox(height: 10),
                _field(
                  'barangay',
                  'Barangay',
                  hint: 'e.g. Muzon',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your barangay'
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _field(
                        'city',
                        'City / Municipality',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _field('province', 'Province')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'zip',
                        'ZIP code',
                        type: TextInputType.number,
                        caps: TextCapitalization.none,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (v) {
                          final z = (v ?? '').trim();
                          if (z.isEmpty) return null;
                          return z.length == 4 ? null : '4 digits';
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _field(
                        'landmark',
                        'Landmark (optional)',
                        hint: 'e.g. near the basketball court',
                        action: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Exactly what the rider will see.
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_rounded, color: accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'THE RIDER WILL SEE',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 10,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w800,
                                color: AppColors.foreground(
                                  context,
                                  const Color(0xFF8B729C),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              preview.isEmpty ? 'Fill in your address' : preview,
                              style: const TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            if (_t('landmark').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Landmark: ${_t('landmark')}',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 12,
                                    color: AppColors.foreground(
                                      context,
                                      Colors.grey[600]!,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.buttonFill(context),
                    foregroundColor: AppColors.onButton(context),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  child: const Text('Confirm address'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
