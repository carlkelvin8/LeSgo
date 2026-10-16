import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/screen_auto_refresh.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../provider/main/riderside/rider_wallet_provider.dart';
import '../../../widgets/widgets.dart';

class RiderWalletHistoryScreen extends ConsumerStatefulWidget {
  const RiderWalletHistoryScreen({super.key});

  @override
  ConsumerState<RiderWalletHistoryScreen> createState() =>
      _RiderWalletHistoryScreenState();
}

class _RiderWalletHistoryScreenState
    extends ConsumerState<RiderWalletHistoryScreen> with WidgetsBindingObserver, AutoRefreshMixin {
  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void onAutoRefresh() {
    _load(silent: true);
  }

  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _loadError;

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    final result =
        await ref.read(riderWalletProvider.notifier).fetchTransactionHistory();
    final list = List<Map<String, dynamic>>.from(result.items);
    list.sort((a, b) {
      final aDate = a['created_at']?.toString() ?? '';
      final bDate = b['created_at']?.toString() ?? '';
      return bDate.compareTo(aDate);
    });
    if (mounted) {
      setState(() {
        _transactions = list;
        _loading = false;
        _loadError = result.error;
      });
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, yyyy • h:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(
              showBackButton: true,
              backgroundColor: Colors.white,
              borderColor: Color(0xFFE5E5E5),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.horizontalPadding(context),
                vertical: ResponsiveUtils.spacing(context, 8),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalization.translate('lespay_history', lang),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 20),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  ResponsiveUtils.horizontalPadding(context),
                            ),
                            child: Text(
                              _loadError ??
                                  'No transactions yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                color: _loadError != null
                                    ? Colors.red.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  ResponsiveUtils.horizontalPadding(context),
                            ),
                            itemCount: _transactions.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              final type =
                                  tx['type']?.toString() ?? 'transaction';
                              final amount = tx['amount'];
                              final desc =
                                  tx['description']?.toString() ?? '';
                              final isCredit = type == 'credit';
                              final amountStr = amount is num
                                  ? amount.toDouble().toStringAsFixed(2)
                                  : amount?.toString() ?? '0.00';

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  desc.isNotEmpty ? desc : type,
                                  style: const TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  _formatDate(tx['created_at']?.toString()),
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: ResponsiveUtils.fontSize(
                                        context, 12),
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Text(
                                  '${isCredit ? '+' : '-'}PHP $amountStr',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontWeight: FontWeight.w700,
                                    color: isCredit
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
