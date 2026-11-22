import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  static Future<void> show(
    BuildContext context,
    ProfileControllers controllers,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: AppColors.surface(context, const Color(0xFFFAF7FC)),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => ProfileEditSection(controllers: controllers),
    );
  }

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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _EditorHeader(),
                    const SizedBox(height: 16),
                    _FieldGroup(
                      title: 'Profile name',
                      children: [
                        _Field(
                          controller: widget.controllers.nameController,
                          label: 'Full name',
                          hint: 'e.g. Juan dela Cruz',
                          icon: Icons.person_outline_rounded,
                          enabled: !busy,
                          validator: (v) =>
                              ProfileValidator.name(v, isRequired: true),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) =>
                              FocusScope.of(context).nextFocus(),
                          keyboardType: TextInputType.name,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FieldGroup(
                      title: 'Profile address',
                      optional: true,
                      children: [
                        _AddressField(
                          controller: widget.controllers.address1Controller,
                          label: 'Street & barangay',
                          hint: 'e.g. Mabini Street, Centro',
                          icon: Icons.location_on_outlined,
                          enabled: !busy,
                          validator: (v) =>
                              ProfileValidator.address(v, isRequired: false),
                        ),
                        const SizedBox(height: 12),
                        _AddressField(
                          controller: widget.controllers.address2Controller,
                          label: 'City & province',
                          hint: 'e.g. Claveria, Cagayan',
                          icon: Icons.map_outlined,
                          enabled: !busy,
                          validator: (v) =>
                              ProfileValidator.address(v, isRequired: false),
                          isLast: true,
                          onLastSubmitted: _save,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.white),
                border: Border(
                  top: BorderSide(
                    color: AppColors.border(context, const Color(0xFFEAE2EF)),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _SaveButton(busy: busy, onTap: busy ? null : _save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader();

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.buttonFill(context);
    return Column(
      children: [
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border(context, const Color(0xFFD8CDDF)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.badge_outlined,
                color: AppColors.onButton(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Personal details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              style: IconButton.styleFrom(
                backgroundColor: accent.withValues(alpha: .08),
                minimumSize: const Size(48, 48),
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 21),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.title,
    required this.children,
    this.optional = false,
  });

  final String title;
  final List<Widget> children;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        border: Border.all(
          color: AppColors.border(context, const Color(0xFFEAE2EF)),
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (optional)
                Text(
                  'Optional',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
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
    _focus = FocusNode()..addListener(_onFocusChanged);
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _focus.dispose();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
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
            suffix: widget.enabled && widget.controller.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear ${widget.label.toLowerCase()}',
                    onPressed: () {
                      widget.controller.clear();
                      setState(() => _suggestions = []);
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        border: Border.all(
          color: AppColors.border(context, const Color(0xFFEDE9F1)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent(
              context,
              const Color(0xFF5F2D82),
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
                              const Color(0xFF292235),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.north_west_rounded,
                        size: 13,
                        color: AppColors.foreground(
                          context,
                          const Color(0xFFCCBBDD),
                        ),
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
      fontSize: 14,
      color: AppColors.foreground(context, const Color(0xFF716778)),
    ),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Icon(
        icon,
        size: 17,
        color: AppColors.accent(context, const Color(0xFF5F2D82)),
      ),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 46),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.surface(context, const Color(0xFFF7F6F9)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.buttonFill(context),
        foregroundColor: AppColors.onButton(context),
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      icon: busy
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.buttonFill(context),
              ),
            )
          : const Icon(Icons.check_rounded, size: 20),
      label: Text(busy ? 'Saving…' : 'Save changes'),
    );
  }
}
