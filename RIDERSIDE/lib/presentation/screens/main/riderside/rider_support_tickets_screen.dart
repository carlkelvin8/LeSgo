import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/mobile_config_service.dart';
import '../../../../core/services/support_api.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_support_provider.dart';
import '../../../widgets/common/retry_widget.dart';
import 'rider_support_ticket_detail_screen.dart';

class RiderSupportTicketsScreen extends ConsumerStatefulWidget {
  const RiderSupportTicketsScreen({super.key});

  @override
  ConsumerState<RiderSupportTicketsScreen> createState() =>
      _RiderSupportTicketsScreenState();
}

class _RiderSupportTicketsScreenState
    extends ConsumerState<RiderSupportTicketsScreen> {
  Map<String, dynamic> _stats = {};
  List<String> _categories = const [];
  String _selectedCategory = 'general';
  bool _loadingMeta = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadMeta();
      if (mounted) {
        ref.read(riderSupportProvider.notifier).loadTickets();
      }
    });
  }

  Future<void> _loadMeta() async {
    try {
      await MobileConfigService.instance.load();
      final stats = await SupportApi.getStatistics();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _categories = MobileConfigService.instance.supportCategories;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
        _loadingMeta = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final lang = ref.read(appLanguageProvider);
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    var category = _selectedCategory;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalization.translate('new_support_ticket', lang)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(labelText: AppLocalization.translate('subject', lang)),
                ),
                if (_categories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: category,
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.replaceAll('_', ' ')),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => category = v);
                    },
                    decoration: InputDecoration(labelText: 'Category'),
                  )
                else
                  TextField(
                    decoration: InputDecoration(labelText: 'Category'),
                    onChanged: (v) => category = v.trim().isEmpty ? 'general' : v.trim(),
                  ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: AppLocalization.translate('description', lang)),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalization.translate('cancel', lang)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalization.translate('submit', lang)),
            ),
          ],
        ),
      ),
    );

    if (created != true || !mounted) return;

    final ok = await ref.read(riderSupportProvider.notifier).createTicket(
          subject: subjectController.text.trim(),
          description: descriptionController.text.trim(),
          category: category,
        );

    subjectController.dispose();
    descriptionController.dispose();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? AppLocalization.translate('support_ticket_created', lang)
              : AppLocalization.translate('could_not_create_ticket', lang),
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderSupportProvider);
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5F2D82),
        title: Text(
          AppLocalization.translate('support', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.fontSize(context, 18),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5F2D82),
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          if (!_loadingMeta && _stats.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E8F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8D9F5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBadge(
                    label: AppLocalization.translate('open', lang),
                    value: '${_stats['open'] ?? _stats['open_count'] ?? 0}',
                  ),
                  _StatBadge(
                    label: AppLocalization.translate('in_progress', lang),
                    value: '${_stats['in_progress'] ?? _stats['in_progress_count'] ?? 0}',
                  ),
                  _StatBadge(
                    label: AppLocalization.translate('resolved', lang),
                    value: '${_stats['resolved'] ?? _stats['resolved_count'] ?? 0}',
                  ),
                ],
              ),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
                  )
                : state.error != null && state.tickets.isEmpty
                    ? RetryWidget(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(riderSupportProvider.notifier).loadTickets(),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF5F2D82),
                        onRefresh: () async {
                          await _loadMeta();
                          await ref
                              .read(riderSupportProvider.notifier)
                              .loadTickets();
                        },
                        child: state.tickets.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: ResponsiveUtils.spacing(context, 80),
                                  ),
                                  Center(
                                    child: Text(
                                      AppLocalization.translate('no_support_tickets', lang),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: EdgeInsets.all(
                                  ResponsiveUtils.spacing(context, 16),
                                ),
                                itemCount: state.tickets.length,
                                separatorBuilder: (_, __) => SizedBox(
                                  height: ResponsiveUtils.spacing(context, 8),
                                ),
                                itemBuilder: (context, index) {
                                  final ticket = state.tickets[index];
                                  return _TicketTile(ticket: ticket);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;

  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF5F2D82),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _TicketTile extends StatelessWidget {
  final RiderSupportTicket ticket;

  const _TicketTile({required this.ticket});

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
      case 'in_progress':
        return Colors.orange.shade700;
      case 'waiting_customer':
        return const Color(0xFF5F2D82);
      case 'resolved':
      case 'closed':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  RiderSupportTicketDetailScreen(ticketId: ticket.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(ticket.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.status.replaceAll('_', ' '),
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 11,
                        color: _statusColor(ticket.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
