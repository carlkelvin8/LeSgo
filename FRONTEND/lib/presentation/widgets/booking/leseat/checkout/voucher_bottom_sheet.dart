import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/voucher_service_utils.dart';
import '../../../../../data/data_source/voucher_remote_datasource.dart';
import '../../../../../data/data_source/dto/voucher/voucher_dto.dart';
import '../../../../../core/di/injection.dart';

/// Shows a bottom sheet with available vouchers from the API.
/// Returns the selected voucher code or null if dismissed.
///
/// [orderValue] is the amount the backend checks against a voucher's minimum
/// order; vouchers above it are shown disabled with how much more to add.
Future<String?> showVoucherBottomSheet(
  BuildContext context, {
  int? serviceId,
  String? title,
  double? orderValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface(context, Colors.white),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _VoucherBottomSheet(
      serviceId: serviceId,
      title: title,
      orderValue: orderValue,
    ),
  );
}

class _VoucherBottomSheet extends ConsumerStatefulWidget {
  const _VoucherBottomSheet({this.serviceId, this.title, this.orderValue});

  final int? serviceId;
  final String? title;
  final double? orderValue;

  @override
  ConsumerState<_VoucherBottomSheet> createState() =>
      _VoucherBottomSheetState();
}

class _VoucherBottomSheetState extends ConsumerState<_VoucherBottomSheet> {
  final _codeController = TextEditingController();
  List<VoucherDto> _vouchers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    try {
      final ds = getIt<VoucherRemoteDataSource>();
      final response = await ds.getAvailableVouchers(
        serviceId: widget.serviceId,
      );
      final vouchers = widget.serviceId == null
          ? response.data
          : filterVouchersForService(response.data, widget.serviceId!);
      if (mounted) {
        setState(() {
          _vouchers = vouchers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surface(context, Colors.grey[300]!),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  widget.title ?? 'Apply Voucher',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Manual code entry
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter voucher code',
                      hintStyle: TextStyle(
                        fontFamily: 'TT Fors',
                        color: AppColors.foreground(context, Colors.grey[400]!),
                      ),
                      filled: true,
                      fillColor: AppColors.surface(context, Colors.grey[100]!),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final code = _codeController.text.trim().toUpperCase();
                    if (code.isNotEmpty) Navigator.pop(context, code);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonFill(context),
                    foregroundColor: AppColors.onButton(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Voucher list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent(context, const Color(0xFF5F2D82)),
                    ),
                  )
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: AppColors.foreground(context, Colors.grey[500]!),
                      ),
                    ),
                  )
                : _vouchers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 48,
                          color: AppColors.foreground(
                            context,
                            Colors.grey[300]!,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.serviceId == null
                              ? 'No vouchers available'
                              : 'No LesGo vouchers available',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            color: AppColors.foreground(
                              context,
                              Colors.grey[500]!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _vouchers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final v = _vouchers[i];
                      final value = widget.orderValue;
                      final shortfall = value != null && v.minOrder > value
                          ? v.minOrder - value
                          : null;
                      final usable = v.eligible && shortfall == null;
                      return _VoucherCard(
                        voucher: v,
                        usable: usable,
                        shortfall: shortfall,
                        onTap: usable
                            ? () => Navigator.pop(context, v.code)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final VoucherDto voucher;
  final VoidCallback? onTap;

  /// Eligible for this customer AND the order meets the minimum.
  final bool usable;

  /// How much more the order needs to reach the voucher's minimum, if short.
  final double? shortfall;

  const _VoucherCard({
    required this.voucher,
    required this.usable,
    this.shortfall,
    this.onTap,
  });

  /// Why a voucher cannot be tapped, so it never looks tappable for no reason.
  String? get _hint {
    if (!voucher.eligible) {
      final reason = voucher.reason?.trim();
      return reason == null || reason.isEmpty ? 'Not available' : reason;
    }
    final missing = shortfall;
    if (missing == null) return null;
    final amount = missing % 1 == 0
        ? missing.toStringAsFixed(0)
        : missing.toStringAsFixed(2);
    return 'Add ₱$amount more to use this voucher';
  }

  @override
  Widget build(BuildContext context) {
    final isEligible = usable;
    final hint = _hint;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isEligible ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEligible
                  ? AppColors.accent(
                      context,
                      Color(0xFF5F2D82),
                    ).withValues(alpha: 0.3)
                  : AppColors.foreground(context, Colors.grey[300]!),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent(
                    context,
                    Color(0xFF5F2D82),
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer,
                  color: AppColors.accent(context, const Color(0xFF5F2D82)),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.title,
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      voucher.description ?? '',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12,
                        color: AppColors.foreground(context, Colors.grey[600]!),
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint,
                        key: ValueKey('voucher-hint-${voucher.code}'),
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD84315),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent(context, Color(0xFF5F2D82)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            voucher.code,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11,
                              color: AppColors.onAccent(context),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          voucher.discountText ?? '',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 12,
                            color: AppColors.accent(
                              context,
                              const Color(0xFF5F2D82),
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isEligible)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.accent(context, const Color(0xFF5F2D82)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
