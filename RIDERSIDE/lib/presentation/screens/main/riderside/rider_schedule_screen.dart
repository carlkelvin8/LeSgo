import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../provider/main/riderside/rider_schedule_provider.dart';

class RiderScheduleScreen extends ConsumerStatefulWidget {
  const RiderScheduleScreen({super.key});

  @override
  ConsumerState<RiderScheduleScreen> createState() =>
      _RiderScheduleScreenState();
}

class _RiderScheduleScreenState extends ConsumerState<RiderScheduleScreen>
    with TickerProviderStateMixin {
  late final AnimationController _emptyAnim;
  late final AnimationController _listAnim;

  static const _accent = Color(0xFF5F2D82);

  @override
  void initState() {
    super.initState();
    _emptyAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _emptyAnim.dispose();
    _listAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final state = ref.watch(riderScheduleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Re-trigger list animation when entries change
    ref.listen<RiderScheduleState>(riderScheduleProvider, (_, __) {
      _listAnim.forward(from: 0);
    });

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF110E1A) : const Color(0xFFF4F2F8),
      appBar: _buildAppBar(context, lang, isDark),
      body: state.entries.isEmpty
          ? _buildEmptyState(context, lang, isDark)
          : _buildList(context, lang, state, isDark),
      floatingActionButton: _AddButton(
        onTap: () => _showAddSheet(context, lang),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppLanguage lang, bool isDark) {
    return AppBar(
      backgroundColor:
          isDark ? const Color(0xFF1E1730) : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: _accent,
              size: 20,
            ),
          ),
        ),
      ),
      title: Text(
        AppLocalization.translate('schedule', lang),
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF1A0A2E),
          letterSpacing: -.3,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: .06)
              : const Color(0xFFEDE9F2),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, AppLanguage lang, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated pulsing clock
            AnimatedBuilder(
              animation: _emptyAnim,
              builder: (_, __) => Transform.scale(
                scale: 1.0 + .06 * _emptyAnim.value,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent.withValues(alpha: .08 + .04 * _emptyAnim.value),
                    border: Border.all(
                      color: _accent.withValues(alpha: .20 + .10 * _emptyAnim.value),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: .12 * _emptyAnim.value),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 44,
                    color: _accent.withValues(alpha: .55 + .20 * _emptyAnim.value),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalization.translate('no_schedules_yet', lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A0A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalization.translate('tap_to_add_availability', lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF9A85B8)
                    : const Color(0xFFAA90C0),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, AppLanguage lang,
      RiderScheduleState state, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: state.entries.length,
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        final start = (index * .12).clamp(0.0, .5);
        final end = (start + .5).clamp(0.0, 1.0);
        final itemAnim = CurvedAnimation(
          parent: _listAnim,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        return AnimatedBuilder(
          animation: itemAnim,
          builder: (_, child) => Opacity(
            opacity: itemAnim.value,
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - itemAnim.value)),
              child: child,
            ),
          ),
          child: _ScheduleCard(
            entry: entry,
            index: index,
            isDark: isDark,
            lang: lang,
            onToggle: () {
              HapticFeedback.selectionClick();
              ref
                  .read(riderScheduleProvider.notifier)
                  .toggleEntry(index);
            },
            onDelete: () => _confirmDelete(context, ref, index, lang),
          ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, int index, AppLanguage lang) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteSheet(
        onConfirm: () {
          ref.read(riderScheduleProvider.notifier).removeEntry(index);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
        lang: lang,
      ),
    );
  }

  void _showAddSheet(BuildContext context, AppLanguage lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddScheduleSheet(
        lang: lang,
        onAdd: (entry) {
          ref.read(riderScheduleProvider.notifier).addEntry(entry);
        },
      ),
    );
  }
}

// ─── Schedule card ────────────────────────────────────────────────────────────
class _ScheduleCard extends StatefulWidget {
  final RiderScheduleEntry entry;
  final int index;
  final bool isDark;
  final AppLanguage lang;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.entry,
    required this.index,
    required this.isDark,
    required this.lang,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  static const _accent = Color(0xFF5F2D82);
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get _dayLabel {
    final n = widget.entry.dayOfWeek == 0 ? 7 : widget.entry.dayOfWeek;
    return _days[(n - 1).clamp(0, 6)];
  }

  String get _fullDay {
    const full = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final n = widget.entry.dayOfWeek == 0 ? 7 : widget.entry.dayOfWeek;
    return full[(n - 1).clamp(0, 6)];
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.entry.isEnabled;
    final surface =
        widget.isDark ? const Color(0xFF1E1730) : Colors.white;
    final border = widget.isDark
        ? const Color(0xFF2E2540)
        : const Color(0xFFEDE9F2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - .015 * _press.value,
          child: child,
        ),
        child: GestureDetector(
          onTapDown: (_) => _press.forward(),
          onTapUp: (_) => _press.reverse(),
          onTapCancel: () => _press.reverse(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled
                    ? _accent.withValues(alpha: .22)
                    : border,
                width: enabled ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: enabled
                      ? _accent.withValues(alpha: widget.isDark ? .10 : .06)
                      : Colors.black.withValues(alpha: .03),
                  blurRadius: enabled ? 16 : 8,
                  offset: const Offset(0, 3),
                  spreadRadius: -3,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                // Day badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: enabled
                        ? _accent.withValues(alpha: widget.isDark ? .18 : .08)
                        : Colors.grey.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: enabled
                          ? _accent.withValues(alpha: .25)
                          : Colors.grey.withValues(alpha: .20),
                      width: .8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayLabel,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: enabled
                              ? _accent
                              : Colors.grey,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Time info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fullDay,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .3,
                          color: widget.isDark
                              ? const Color(0xFF9A85B8)
                              : const Color(0xFFAA90C0),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.entry.startTime} – ${widget.entry.endTime}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? (widget.isDark
                                  ? Colors.white
                                  : const Color(0xFF1A0A2E))
                              : Colors.grey,
                          letterSpacing: -.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: enabled
                                  ? const Color(0xFF22A060)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            enabled
                                ? AppLocalization.translate('active', widget.lang)
                                : AppLocalization.translate(
                                    'inactive', widget.lang),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: enabled
                                  ? const Color(0xFF22A060)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Toggle + delete
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch.adaptive(
                      value: enabled,
                      activeTrackColor: _accent,
                      activeThumbColor: Colors.white,
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade200,
                      onChanged: (_) => widget.onToggle(),
                    ),
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red.withValues(alpha: .60),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Add schedule bottom sheet ────────────────────────────────────────────────
class _AddScheduleSheet extends StatefulWidget {
  final AppLanguage lang;
  final ValueChanged<RiderScheduleEntry> onAdd;

  const _AddScheduleSheet({required this.lang, required this.onAdd});

  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  int _selectedDay = 1;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);

  static const _days = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const _accent = Color(0xFF5F2D82);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1730) : Colors.white;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(
        opacity: CurvedAnimation(
          parent: _anim,
          curve: Curves.easeOut,
        ).value,
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - _anim.value)),
          child: child,
        ),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .18),
              blurRadius: 32,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: .12)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              AppLocalization.translate('add_schedule', widget.lang),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                letterSpacing: -.3,
              ),
            ),
            const SizedBox(height: 20),

            // Day chips
            Text(
              'DAY',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: isDark
                    ? const Color(0xFF9A85B8)
                    : const Color(0xFFAA90C0),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = _selectedDay == i + 1;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDay = i + 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 46,
                      decoration: BoxDecoration(
                        color: selected
                            ? _accent
                            : _accent.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? _accent
                              : _accent.withValues(alpha: .18),
                          width: selected ? 0 : .8,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: _accent.withValues(alpha: .35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          _days[i],
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : _accent,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            // Time row
            Text(
              'TIME',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: isDark
                    ? const Color(0xFF9A85B8)
                    : const Color(0xFFAA90C0),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Start',
                    time: _fmt(_start),
                    isDark: isDark,
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _start,
                      );
                      if (t != null) setState(() => _start = t);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '→',
                    style: TextStyle(
                      fontSize: 20,
                      color: isDark
                          ? const Color(0xFF9A85B8)
                          : const Color(0xFFAA90C0),
                    ),
                  ),
                ),
                Expanded(
                  child: _TimePicker(
                    label: 'End',
                    time: _fmt(_end),
                    isDark: isDark,
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _end,
                      );
                      if (t != null) setState(() => _end = t);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Add button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onAdd(RiderScheduleEntry(
                    dayOfWeek: _selectedDay,
                    startTime: _fmt(_start),
                    endTime: _fmt(_end),
                  ));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  AppLocalization.translate('add_schedule', widget.lang),
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Time picker tile ─────────────────────────────────────────────────────────
class _TimePicker extends StatelessWidget {
  final String label;
  final String time;
  final bool isDark;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.isDark,
    required this.onTap,
  });

  static const _accent = Color(0xFF5F2D82);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: isDark ? .12 : .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _accent.withValues(alpha: .18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: .4,
                color: isDark
                    ? const Color(0xFF9A85B8)
                    : const Color(0xFFAA90C0),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: _accent),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Delete confirmation sheet ────────────────────────────────────────────────
class _DeleteSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final AppLanguage lang;

  const _DeleteSheet({
    required this.onConfirm,
    required this.onCancel,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1730) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: .12)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline_rounded,
                size: 26, color: Colors.red),
          ),
          const SizedBox(height: 14),
          Text(
            'Remove Schedule',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A0A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This schedule will be permanently removed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF9A85B8)
                  : const Color(0xFFAA90C0),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF2E2540)
                          : const Color(0xFFEDE9F2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    AppLocalization.translate('cancel', lang),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Animated Add FAB ─────────────────────────────────────────────────────────
class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await _ctrl.forward();
        await _ctrl.reverse();
        widget.onTap();
      },
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: 1.0 - .04 * _ctrl.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B3FC8), Color(0xFF5F2D82)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5F2D82).withValues(alpha: .40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add Schedule',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
