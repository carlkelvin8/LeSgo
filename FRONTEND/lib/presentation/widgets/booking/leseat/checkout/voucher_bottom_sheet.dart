import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../data/data_source/voucher_remote_datasource.dart';
import '../../../../../data/data_source/dto/voucher/voucher_dto.dart';
import '../../../../../core/di/injection.dart';

/// Shows a bottom sheet with available vouchers from the API.
/// Returns the selected voucher code or null if dismissed.
Future<String?> showVoucherBottomSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _VoucherBottomSheet(),
  );
}

class _VoucherBottomSheet extends ConsumerStatefulWidget {
  const _VoucherBottomSheet();

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
      final response = await ds.getAvailableVouchers();
      if (mounted) {
        setState(() {
          _vouchers = response.data;
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Apply Voucher',
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
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
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
                    backgroundColor: const Color(0xFF5F2D82),
                    foregroundColor: Colors.white,
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
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF5F2D82),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            color: Colors.grey[500],
                          ),
                        ),
                      )
                    : _vouchers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_offer_outlined,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'No vouchers available',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _vouchers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final v = _vouchers[i];
                              return _VoucherCard(
                                voucher: v,
                                onTap: v.eligible
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

  const _VoucherCard({required this.voucher, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEligible = voucher.eligible;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isEligible ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEligible
                  ? const Color(0xFF5F2D82).withValues(alpha: 0.3)
                  : Colors.grey[300]!,
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
                  color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_offer,
                  color: Color(0xFF5F2D82),
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
                      voucher.description,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F2D82),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            voucher.code,
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          voucher.discountText,
                          style: const TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 12,
                            color: Color(0xFF5F2D82),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isEligible)
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF5F2D82),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
