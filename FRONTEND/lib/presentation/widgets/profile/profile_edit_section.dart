import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/validators/profile_validator.dart';
import '../../provider/main/profile/controller/profile.controller.notifier.dart';
import '../../provider/main/profile/profile_provider.dart';

// ─── Philippine address suggestions ──────────────────────────────────────────
const _phCities = [
  // NCR
  'Manila', 'Quezon City', 'Caloocan', 'Las Piñas', 'Makati', 'Malabon',
  'Mandaluyong', 'Marikina', 'Muntinlupa', 'Navotas', 'Parañaque', 'Pasay',
  'Pasig', 'Pateros', 'San Juan', 'Taguig', 'Valenzuela',
  // Luzon
  'Baguio', 'Angeles', 'Olongapo', 'San Fernando, Pampanga', 'Cabanatuan',
  'San Jose City',
  'Palayan',
  'Tarlac City',
  'Dagupan',
  'San Carlos, Pangasinan',
  'Urdaneta', 'Vigan', 'Laoag', 'Batac', 'Tuguegarao', 'Ilagan', 'Santiago',
  'Cauayan', 'Legazpi', 'Ligao', 'Tabaco', 'Sorsogon City', 'Naga', 'Iriga',
  // Visayas
  'Cebu City', 'Mandaue', 'Lapu-Lapu', 'Danao', 'Talisay, Cebu', 'Toledo',
  'Carcar', 'Bogo', 'Bacolod', 'Bago', 'Cadiz', 'Escalante', 'Himamaylan',
  'Kabankalan', 'La Carlota', 'Sagay', 'Silay', 'Sipalay', 'Talisay, Negros',
  'Victorias', 'Tacloban', 'Ormoc', 'Calbayog', 'Catbalogan', 'Borongan',
  'Maasin', 'Baybay', 'Iloilo City', 'Passi', 'Roxas City',
  // Mindanao
  'Davao City', 'Tagum', 'Panabo', 'Samal', 'Digos', 'Mati', 'Cagayan de Oro',
  'Gingoog', 'El Salvador', 'Oroquieta', 'Ozamiz', 'Tangub', 'Pagadian',
  'Dipolog', 'Dapitan', 'General Santos', 'Koronadal', 'Tacurong',
  'Kidapawan', 'Cotabato City', 'Iligan', 'Marawi', 'Zamboanga City',
  'Isabela, Basilan', 'Lamitan',
];

const _phBarangays = [
  'Barangay 1',
  'Barangay 2',
  'Barangay 3',
  'Poblacion',
  'Pob.',
  'Brgy. San Antonio',
  'Brgy. Santa Cruz',
  'Brgy. Santa Rosa',
  'Brgy. San Jose',
  'Brgy. San Pedro',
  'Brgy. San Miguel',
  'Brgy. Bagong Silang',
  'Brgy. Bagumbayan',
  'Brgy. Maligaya',
  'Brgy. Mapayapa',
  'Brgy. Masagana',
  'Brgy. Bagong Pag-Asa',
  'Brgy. Commonwealth',
  'Brgy. Holy Spirit',
  'Brgy. Payatas',
  'Brgy. Batasan Hills',
  'Brgy. Fairview',
];

const _phProvinces = [
  'Metro Manila',
  'Cebu',
  'Davao del Sur',
  'Bukidnon',
  'Laguna',
  'Batangas',
  'Cavite',
  'Rizal',
  'Bulacan',
  'Pampanga',
  'Tarlac',
  'Nueva Ecija',
  'Pangasinan',
  'Ilocos Norte',
  'Ilocos Sur',
  'La Union',
  'Cagayan',
  'Isabela',
  'Albay',
  'Camarines Sur',
  'Sorsogon',
  'Masbate',
  'Romblon',
  'Negros Occidental',
  'Negros Oriental',
  'Iloilo',
  'Capiz',
  'Aklan',
  'Antique',
  'Guimaras',
  'Leyte',
  'Eastern Samar',
  'Western Samar',
  'Biliran',
  'Bohol',
  'Siquijor',
  'Misamis Oriental',
  'Misamis Occidental',
  'Zamboanga del Norte',
  'Zamboanga del Sur',
  'North Cotabato',
  'South Cotabato',
  'Maguindanao',
  'Lanao del Norte',
  'Lanao del Sur',
  'Sultan Kudarat',
  'Sarangani',
  'Davao Oriental',
  'Davao del Norte',
  'Compostela Valley',
  'Agusan del Norte',
  'Agusan del Sur',
];

List<String> _suggestAddress(String query) {
  if (query.trim().length < 2) return [];
  final q = query.toLowerCase();
  final all = [..._phBarangays, ..._phCities, ..._phProvinces];
  return all.where((s) => s.toLowerCase().contains(q)).take(6).toList();
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class ProfileEditSection extends ConsumerStatefulWidget {
  final ProfileControllers controllers;
  const ProfileEditSection({super.key, required this.controllers});

  @override
  ConsumerState<ProfileEditSection> createState() => _ProfileEditSectionState();
}

class _ProfileEditSectionState extends ConsumerState<ProfileEditSection> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;

  Future<void> _save() async {
    if (_saving ||
        ref.read(profileProvider).isUpdating ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.controllers.updateProfile(context, ref);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy =
        _saving || ref.watch(profileProvider.select((s) => s.isUpdating));

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(),

          // Full name
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _Field(
              controller: widget.controllers.nameController,
              label: 'Full name',
              hint: 'e.g. Juan dela Cruz',
              icon: Icons.person_outline_rounded,
              enabled: !busy,
              validator: (v) => ProfileValidator.name(v, isRequired: true),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              keyboardType: TextInputType.name,
            ),
          ),

          // Address 1 — with suggestions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _AddressField(
              controller: widget.controllers.address1Controller,
              label: 'Street & barangay',
              hint: 'Street, Barangay',
              icon: Icons.location_on_outlined,
              enabled: !busy,
              validator: (v) => ProfileValidator.address(v, isRequired: false),
            ),
          ),

          // Address 2 — with suggestions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _AddressField(
              controller: widget.controllers.address2Controller,
              label: 'City & province',
              hint: 'City, Province',
              icon: Icons.map_outlined,
              enabled: !busy,
              validator: (v) => ProfileValidator.address(v, isRequired: false),
              isLast: true,
              onLastSubmitted: _save,
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: _SaveButton(busy: busy, onTap: busy ? null : _save),
          ),
        ],
      ),
    );
  }
}

// ─── Card header ──────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Make it yours',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
            color: AppColors.foreground(context, Color(0xFF292235)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your details. Your everyday destinations.',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            height: 1.5,
            color: AppColors.foreground(context, Color(0xFF82788D)),
          ),
        ),
      ],
    ),
  );
}

// ─── Regular field ────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool enabled;
  final String? Function(String?) validator;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSubmitted;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.validator,
    required this.textInputAction,
    required this.onSubmitted,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textCapitalization: TextCapitalization.words,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onFieldSubmitted: onSubmitted,
      style: _fieldTextStyle(context),
      decoration: _decoration(context, label, hint, icon),
    );
  }
}

// ─── Address field with suggestions ──────────────────────────────────────────
class _AddressField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool enabled;
  final String? Function(String?) validator;
  final bool isLast;
  final VoidCallback? onLastSubmitted;

  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.validator,
    this.isLast = false,
    this.onLastSubmitted,
  });

  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
  late final FocusNode _focus;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _focus.dispose();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final s = _suggestAddress(widget.controller.text);
    if (mounted) setState(() => _suggestions = s);
  }

  void _pick(String value) {
    widget.controller.text = value;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
    setState(() => _suggestions = []);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field
        TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          enabled: widget.enabled,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textCapitalization: TextCapitalization.words,
          textInputAction: widget.isLast
              ? TextInputAction.done
              : TextInputAction.next,
          keyboardType: TextInputType.streetAddress,
          onFieldSubmitted: (_) {
            if (widget.isLast) {
              widget.onLastSubmitted?.call();
            } else {
              FocusScope.of(context).nextFocus();
            }
          },
          style: _fieldTextStyle(context),
          decoration: _decoration(
            context,
            widget.label,
            widget.hint,
            widget.icon,
            suffix: widget.controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      setState(() => _suggestions = []);
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.foreground(context, Color(0xFFBBAACC)),
                    ),
                  )
                : null,
          ),
        ),

        // Suggestion dropdown
        if (_suggestions.isNotEmpty && _focus.hasFocus)
          _SuggestionList(suggestions: _suggestions, onPick: _pick),
      ],
    );
  }
}

// ─── Suggestion dropdown ──────────────────────────────────────────────────────
class _SuggestionList extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onPick;

  const _SuggestionList({required this.suggestions, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context, Color(0xFFEDE9F1))),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent(
              context,
              Color(0xFF5F2D82),
            ).withValues(alpha: .10),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        children: suggestions.asMap().entries.map((e) {
          final idx = e.key;
          final s = e.value;
          return Column(
            children: [
              InkWell(
                onTap: () => onPick(s),
                borderRadius: BorderRadius.vertical(
                  top: idx == 0 ? const Radius.circular(14) : Radius.zero,
                  bottom: idx == suggestions.length - 1
                      ? const Radius.circular(14)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Color(0xFF9B70CC),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.foreground(
                              context,
                              Color(0xFF292235),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.north_west_rounded,
                        size: 13,
                        color: AppColors.foreground(context, Color(0xFFCCBBDD)),
                      ),
                    ],
                  ),
                ),
              ),
              if (idx < suggestions.length - 1)
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                  indent: 38,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Shared input style ───────────────────────────────────────────────────────
TextStyle _fieldTextStyle(BuildContext context) => TextStyle(
  fontFamily: 'TT Fors',
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: AppColors.foreground(context, const Color(0xFF292235)),
);

InputDecoration _decoration(
  BuildContext context,
  String label,
  String hint,
  IconData icon, {
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    hintText: hint,
    labelStyle: TextStyle(
      fontFamily: 'TT Fors',
      fontSize: 12,
      color: AppColors.foreground(context, const Color(0xFF82788D)),
    ),
    hintStyle: TextStyle(
      fontFamily: 'TT Fors',
      fontSize: 12,
      color: AppColors.foreground(context, const Color(0xFFCCBBDD)),
    ),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Icon(
        icon,
        size: 17,
        color: AppColors.accent(context, const Color(0xFF9B70CC)),
      ),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 46),
    suffixIcon: suffix != null
        ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
        : null,
    suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    filled: true,
    fillColor: AppColors.surface(context, const Color(0xFFF7F6F9)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
    errorMaxLines: 2,
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: AppColors.border(context, const Color(0xFFEDE9F1)),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: AppColors.border(context, const Color(0xFFEDE9F1)),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF7B3FAA), width: 1.8),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: AppColors.border(context, Colors.grey.shade200),
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE05050), width: 1.4),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE05050), width: 1.8),
    ),
  );
}

// ─── Save button ──────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;
  const _SaveButton({required this.busy, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: busy
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF7546A0), Color(0xFF573275)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: busy ? AppColors.foreground(context, Color(0xFFE0D4EE)) : null,
          borderRadius: BorderRadius.circular(15),
          boxShadow: busy
              ? []
              : [
                  BoxShadow(
                    color: AppColors.accent(
                      context,
                      Color(0xFF5F2D82),
                    ).withValues(alpha: .32),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                    spreadRadius: -4,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF7B3FAA),
                ),
              )
            else
              const Icon(Icons.check_rounded, color: Colors.white, size: 19),
            const SizedBox(width: 9),
            Text(
              busy ? 'Saving…' : 'Save changes',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 15),
                fontWeight: FontWeight.w700,
                color: busy ? const Color(0xFF7B3FAA) : Colors.white,
                letterSpacing: .1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
