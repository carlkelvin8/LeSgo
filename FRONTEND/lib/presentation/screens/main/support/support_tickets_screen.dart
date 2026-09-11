import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/auth/auth_routes.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/support/support_provider.dart';
import '../../../widgets/common/retry_widget.dart';
import '../../../widgets/widgets.dart';
import '../../../../data/data_source/dto/support/support_dto.dart';
import 'support_ticket_detail_screen.dart';

class SupportTicketsScreen extends ConsumerWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: const AuthHeader(title: 'Support'),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F2D82),
                      ),
                    )
                  : state.error != null && state.tickets.isEmpty
                  ? RetryWidget(
                      message: state.error!,
                      actionLabel: state.requiresLogin ? 'Log In' : 'Try Again',
                      actionIcon: state.requiresLogin
                          ? Icons.login
                          : Icons.refresh,
                      onRetry: state.requiresLogin
                          ? () => AppRouter.pushAndRemoveUntil(
                              context,
                              LoginRoutes.login,
                            )
                          : () => ref
                                .read(supportProvider.notifier)
                                .loadTickets(),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF5F2D82),
                      onRefresh: () =>
                          ref.read(supportProvider.notifier).loadTickets(),
                      child: state.tickets.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: ResponsiveUtils.spacing(context, 80),
                                ),
                                Center(
                                  child: Text(
                                    'No support tickets yet.',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: ResponsiveUtils.fontSize(
                                        context,
                                        14,
                                      ),
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
                              separatorBuilder: (_, _) => SizedBox(
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5F2D82),
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController(text: 'general_inquiry');
    final picker = ImagePicker();
    final attachments = <XFile>[];

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Support Ticket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final files = await picker.pickMultiImage(
                        imageQuality: 85,
                      );
                      if (files.isNotEmpty) {
                        setDialogState(() {
                          attachments
                            ..clear()
                            ..addAll(files.take(3));
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      attachments.isEmpty
                          ? 'Add attachments'
                          : '${attachments.length} attachment(s)',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (created != true || !context.mounted) return;

    final ok = await ref
        .read(supportProvider.notifier)
        .createTicket(
          CreateTicketDto(
            subject: subjectController.text.trim(),
            description: descriptionController.text.trim(),
            category: categoryController.text.trim(),
          ),
          attachments: attachments,
        );

    if (context.mounted && ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Support ticket created')));
    }
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});

  final SupportTicketDto ticket;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        ticket.subject,
        style: const TextStyle(
          fontFamily: 'TT Fors',
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${ticket.status} · ${ticket.priority}',
        style: TextStyle(
          fontFamily: 'TT Fors',
          color: Colors.grey.shade600,
          fontSize: ResponsiveUtils.fontSize(context, 12),
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SupportTicketDetailScreen(ticketId: ticket.id),
          ),
        );
      },
    );
  }
}
