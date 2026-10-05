import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../data/data_source/dto/support/support_dto.dart';
import '../../../../data/data_source/support_remote_datasource.dart';
import 'support_ticket_detail_screen.dart';

const _purple = Color(0xFF5F2D82);
const _canvas = Color(0xFFF8F7FB);

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final _dataSource = getIt<SupportRemoteDataSource>();
  late Future<List<SupportTicketDto>> _tickets;

  @override
  void initState() {
    super.initState();
    _tickets = _dataSource.getTickets();
  }

  void _reload() {
    setState(() {
      _tickets = _dataSource.getTickets();
    });
  }

  String _date(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    return date == null ? '' : DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.surface(context, _canvas),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context, Colors.white),
        surfaceTintColor: AppColors.surface(context, Colors.white),
        iconTheme:  IconThemeData(color: AppColors.foreground(context, Colors.black87)),
        title:  Text(
          'Support',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground(context, Colors.black87),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'LeSgo help',
            icon:  Icon(Icons.help_outline, color: AppColors.accent(context, _purple)),
            onPressed: () =>
                AppRouter.push(context, MainRoutes.customerServiceChat),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(hp, 16, hp, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your conversations',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<SupportTicketDto>>(
              future: _tickets,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Could not load conversations. Retry'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return  Center(
                    child: CircularProgressIndicator(color: AppColors.accent(context, _purple)),
                  );
                }
                final tickets = snapshot.data!;
                if (tickets.isEmpty) {
                  return  Center(
                    child: Text(
                      'Your conversations will appear here.',
                      style: TextStyle(color: AppColors.foreground(context, Colors.black54)),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: tickets.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final ticket = tickets[index];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: hp + 4,
                        vertical: 6,
                      ),
                      leading:  CircleAvatar(
                        backgroundColor: AppColors.surface(context, Color(0xFFF0E7F6)),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.accent(context, _purple),
                        ),
                      ),
                      title: Text(
                        ticket.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${ticket.status.replaceAll('_', ' ')} · ${_date(ticket.updatedAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        AppRouter.push(
                          context,
                          MainRoutes.supportTicketDetail,
                          arguments: ticket.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(hp, 8, hp, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const SupportTicketDetailScreen(ticketId: null),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent(context, _purple),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.support_agent),
                  label: const Text(
                    'Start a new chat',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}