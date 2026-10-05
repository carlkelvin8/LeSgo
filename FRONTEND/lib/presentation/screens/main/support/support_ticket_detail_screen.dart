import 'package:lesgo/core/theme/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../data/data_source/support_remote_datasource.dart';
import '../../../../data/data_source/dto/support/support_dto.dart';

const _purple = Color(0xFF5F2D82);
const _canvas = Color(0xFFF8F7FB);

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({super.key, this.ticketId});
  final int? ticketId;
  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen>
    with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _commentController = TextEditingController();
  final _scroll = ScrollController();
  final _dataSource = getIt<SupportRemoteDataSource>();
  final _uploadService = getIt<FileUploadService>();
  final List<XFile> _attachments = [];
  SupportTicketDetail? _detail;
  int? _ticketId;
  Timer? _timer;
  bool _loading = false, _sending = false, _refreshing = false, _rating = false;
  int _selectedRating = 5;
  String? _error;
  String _topic = 'Something else';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticketId = widget.ticketId;
    if (_ticketId != null) _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          !_sending) {
        _load(quiet: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(quiet: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _commentController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _load({bool quiet = false}) async {
    if (_ticketId == null || _refreshing) return;
    _refreshing = true;
    if (!quiet) setState(() => _loading = true);
    final nearBottom =
        !_scroll.hasClients || _scroll.position.extentAfter < 100;
    final previousCount = _detail?.messages.length ?? 0;
    try {
      final detail = await _dataSource.getTicket(_ticketId!);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _error = null;
      });
      if (!quiet || (nearBottom && detail.messages.length != previousCount)) {
        _bottom();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = ApiErrorMapper.message(
            e,
            fallbackEn: 'Messages could not refresh. Tap to retry.',
            fallbackTl: 'Hindi ma-refresh ang messages. Subukan muli.',
          ),
        );
      }
    } finally {
      _refreshing = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ApiErrorMapper.message(
            e,
            fallbackEn:
                'Could not send. Your message is saved here; please retry.',
            fallbackTl: 'Hindi na-send. Subukan muli.',
          ),
        ),
      ),
    );
  }

  Future<void> _pick() async {
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (!mounted || _sending) return;
      setState(() => _attachments.addAll(files.take(3 - _attachments.length)));
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (_sending || (text.isEmpty && _attachments.isEmpty)) return;
    setState(() => _sending = true);
    try {
      final urls = _attachments.isEmpty
          ? <String>[]
          : await _uploadService.uploadFiles(
              List.of(_attachments),
              context: 'support',
              uploadPath: ApiConstants.supportUpload,
            );
      final message = text.isEmpty ? 'Attachment shared' : text;
      if (_ticketId == null) {
        final ticket = await _dataSource.createTicket(
          CreateTicketDto(
            subject: _topic == 'Something else' ? 'Live agent support' : _topic,
            description: message,
            category: switch (_topic) {
              'Order help' => 'order_issue',
              'Payment concern' => 'payment_issue',
              'Account help' => 'account_issue',
              _ => 'general_inquiry',
            },
          ),
          attachments: urls,
        );
        _ticketId = ticket.id;
      } else {
        await _dataSource.addMessage(_ticketId!, message, attachments: urls);
      }
      if (!mounted) return;
      _messageController.clear();
      setState(() => _attachments.clear());
      await _load(quiet: true);
      _bottom();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _history() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface(context, Colors.white),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.7,
        child: _ConversationHistory(
          dataSource: _dataSource,
          onSelect: (ticket) {
            Navigator.pop(sheetContext);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SupportTicketDetailScreen(ticketId: ticket.id),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    setState(() => _rating = true);
    try {
      await _dataSource.rateSatisfaction(
        _ticketId!,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );
      await _load(quiet: true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _rating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final closed = ['closed', 'cancelled'].contains(_detail?.ticket.status);
    final status = _detail?.ticket.status.replaceAll('_', ' ');
    return Scaffold(
      backgroundColor: AppColors.surface(context, _canvas),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context, Colors.white),
        surfaceTintColor: AppColors.surface(context, Colors.white),
        titleSpacing: 0,
        toolbarHeight: 78,
        title: Row(
          children: [
             CircleAvatar(
              backgroundColor: AppColors.surface(context, Color(0xFFF0E7F6)),
              child: Icon(Icons.support_agent_rounded, color: AppColors.accent(context, _purple)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Agent',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _ticketId == null
                        ? 'LeSgo customer support'
                        : 'Conversation #$_ticketId',
                    style:  TextStyle(fontSize: 12, color: AppColors.foreground(context, Colors.black54)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Conversation history',
            onPressed: _history,
            icon:  Icon(Icons.history_rounded, color: AppColors.accent(context, _purple)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.surface(context, Color(0xFFF0EAF5)),
              child: Row(
                children: [
                   Icon(Icons.shield_outlined, size: 16, color: AppColors.accent(context, _purple)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ticketId == null
                          ? 'A little help, whenever you need it.'
                          : 'Status: ${status ?? 'Loading'} · Replies appear here',
                      style:  TextStyle(color: AppColors.accent(context, _purple), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Material(
                color: AppColors.surface(context, Color(0xFFFFF1E5)),
                child: InkWell(
                  onTap: () => _load(quiet: true),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.refresh, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _loading && _detail == null
                  ?  Center(
                      child: CircularProgressIndicator(color: AppColors.accent(context, _purple)),
                    )
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      children: [
                        if (_ticketId == null) ..._welcome(),
                        if (_detail != null) ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                _date(_detail!.ticket.createdAt),
                                style:  TextStyle(
                                  color: AppColors.foreground(context, Colors.black45),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          ..._detail!.messages.map(
                            (m) => _MessageBubble(message: m),
                          ),
                          if (_detail!.messages.isEmpty)
                            const Text('Your conversation is ready.'),
                          if (_detail!.canRateSatisfaction)
                            _SatisfactionCard(
                              selectedRating: _selectedRating,
                              commentController: _commentController,
                              submitting: _rating,
                              onRatingChanged: (v) =>
                                  setState(() => _selectedRating = v),
                              onSubmit: _submitRating,
                            ),
                          if (_detail!.satisfactionRating != null)
                            Center(
                              child: Text(
                                'Thanks for your feedback · ${_detail!.satisfactionRating}/5',
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
            if (closed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('This conversation has ended.'),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const SupportTicketDetailScreen(),
                        ),
                      ),
                      child: const Text('Start a new chat'),
                    ),
                  ],
                ),
              )
            else
              _composer(),
          ],
        ),
      ),
    );
  }

  List<Widget> _welcome() => [
    const SizedBox(height: 12),
     Center(
      child: CircleAvatar(
        radius: 36,
        backgroundColor: AppColors.surface(context, Color(0xFFEDE2F5)),
        child: Icon(Icons.waving_hand_rounded, color: AppColors.accent(context, _purple), size: 32),
      ),
    ),
    const SizedBox(height: 18),
    const Text(
      'How can we help?',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
    ),
    const SizedBox(height: 8),
     Text(
      'Tell us what happened. Our support team\nwill reply in this conversation.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.foreground(context, Colors.black54), fontSize: 13, height: 1.6),
    ),
    const SizedBox(height: 30),
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context, Color(0xFFECE6F0))),
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LET’S GET STARTED',
            style: TextStyle(
              color: AppColors.accent(context, _purple),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Share your concern below',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'You can include an order number or add a screenshot to help us understand.',
            style: TextStyle(color: AppColors.foreground(context, Colors.black54), fontSize: 12, height: 1.6),
          ),
        ],
      ),
    ),
    const SizedBox(height: 22),
     Text(
      'What is this about?',
      style: TextStyle(fontSize: 12, color: AppColors.foreground(context, Colors.black54)),
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          ['Order help', 'Payment concern', 'Account help', 'Something else']
              .map(
                (topic) => ChoiceChip(
                  label: Text(topic, style: const TextStyle(fontSize: 12)),
                  selected: _topic == topic,
                  selectedColor: const Color(0xFFEDE2F5),
                  backgroundColor: AppColors.surface(context, Colors.white),
                  side:  BorderSide(color: AppColors.border(context, Color(0xFFE3DAEB))),
                  onSelected: _sending
                      ? null
                      : (_) => setState(() => _topic = topic),
                ),
              )
              .toList(),
    ),
  ];

  Widget _composer() => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration:  BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        border: Border(top: BorderSide(color: AppColors.border(context, Color(0xFFECE6F0)))),
      ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_attachments.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _attachments
                  .map(
                    (file) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        label: SizedBox(
                          width: 100,
                          child: Text(
                            file.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        avatar: const Icon(Icons.image_outlined, size: 16),
                        onDeleted: _sending
                            ? null
                            : () => setState(() => _attachments.remove(file)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Attach images (up to 3)',
              onPressed: _sending || _attachments.length == 3 ? null : _pick,
              icon:  Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.accent(context, _purple),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !_sending,
                minLines: 1,
                maxLines: 4,
                maxLength: 5000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type your message…',
                  counterText: '',
                  hintStyle:  TextStyle(
                    fontSize: 13,
                    color: AppColors.foreground(context, Colors.black45),
                  ),
                  filled: true,
                  fillColor: AppColors.surface(context, _canvas),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (_, value, child) => IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Send message',
                onPressed:
                    _sending ||
                        (value.text.trim().isEmpty && _attachments.isEmpty)
                    ? null
                    : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
         Text(
          'Messages go to the LeSgo support team',
          style: TextStyle(fontSize: 10, color: AppColors.foreground(context, Colors.black45)),
        ),
      ],
    ),
  );
}

String _date(String raw) {
  final date = DateTime.tryParse(raw)?.toLocal();
  return date == null ? '' : DateFormat('MMM d, yyyy').format(date);
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final TicketMessageDto message;
  @override
  Widget build(BuildContext context) {
    final staff = message.isStaff;
    final date = DateTime.tryParse(message.createdAt)?.toLocal();
    return Align(
      alignment: staff ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: staff
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 5, left: 4, right: 4),
                child: Text(
                  staff ? 'LeSgo Support' : 'You',
                  style:  TextStyle(fontSize: 10, color: AppColors.foreground(context, Colors.black54)),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: staff ? AppColors.surface(context, Colors.white) : AppColors.accent(context, _purple),
                    border: staff
                        ? Border.all(color: AppColors.border(context, Color(0xFFECE6F0)))
                        : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(staff ? 4 : 18),
                    bottomRight: Radius.circular(staff ? 18 : 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.message,
                      style: TextStyle(
                        color: staff ? AppColors.foreground(context, Colors.black87) : Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    ...message.attachments.map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url,
                            width: 220,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) =>  Text(
                              'Image unavailable',
                              style: TextStyle(color: AppColors.foreground(context, Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (date != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 4, right: 4),
                  child: Text(
                    DateFormat('MMM d · h:mm a').format(date),
                    style:  TextStyle(fontSize: 10, color: AppColors.foreground(context, Colors.black45)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationHistory extends StatefulWidget {
  const _ConversationHistory({
    required this.dataSource,
    required this.onSelect,
  });
  final SupportRemoteDataSource dataSource;
  final ValueChanged<SupportTicketDto> onSelect;
  @override
  State<_ConversationHistory> createState() => _ConversationHistoryState();
}

class _ConversationHistoryState extends State<_ConversationHistory> {
  late Future<List<SupportTicketDto>> _tickets;
  @override
  void initState() {
    super.initState();
    _tickets = widget.dataSource.getTickets();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Your conversations',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<SupportTicketDto>>(
          future: _tickets,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _tickets = widget.dataSource.getTickets();
                  }),
                  child: const Text('Could not load conversations. Retry'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return  Center(
                child: CircularProgressIndicator(color: AppColors.accent(context, _purple)),
              );
            }
            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Your conversations will appear here.'),
              );
            }
            return ListView.separated(
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, index) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (_, index) {
                final ticket = snapshot.data![index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
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
                  ),
                  subtitle: Text(
                    '${ticket.status.replaceAll('_', ' ')} · ${_date(ticket.updatedAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.onSelect(ticket),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

class _SatisfactionCard extends StatelessWidget {
  const _SatisfactionCard({
    required this.selectedRating,
    required this.commentController,
    required this.submitting,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final int selectedRating;
  final TextEditingController commentController;
  final bool submitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate your support experience',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: submitting ? null : () => onRatingChanged(star),
                  icon: Icon(
                    star <= selectedRating ? Icons.star : Icons.star_border,
                    color: AppColors.accent(context, Color(0xFF5F2D82)),
                  ),
                );
              }),
            ),
            TextField(
              controller: commentController,
              enabled: !submitting,
              decoration: const InputDecoration(labelText: 'Optional comment'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit rating'),
            ),
          ],
        ),
      ),
    );
  }
}
