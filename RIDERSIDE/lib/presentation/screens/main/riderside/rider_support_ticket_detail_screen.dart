import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/services/support_api.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../widgets/common/retry_widget.dart';

class RiderSupportTicketDetailScreen extends StatefulWidget {
  const RiderSupportTicketDetailScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<RiderSupportTicketDetailScreen> createState() =>
      _RiderSupportTicketDetailScreenState();
}

class _RiderSupportTicketDetailScreenState
    extends State<RiderSupportTicketDetailScreen> {
  final _messageController = TextEditingController();
  final _commentController = TextEditingController();
  final _picker = ImagePicker();
  RiderSupportTicketDetail? _detail;
  List<XFile> _pendingAttachments = [];
  bool _loading = true;
  bool _sending = false;
  bool _rating = false;
  int _selectedRating = 5;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await SupportApi.getTicket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  Future<void> _pickAttachments() async {
    if (_pendingAttachments.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 attachments per message')),
      );
      return;
    }
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _pendingAttachments.addAll(
        picked.take(3 - _pendingAttachments.length),
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;
    setState(() => _sending = true);
    try {
      List<String> attachmentUrls = [];
      if (_pendingAttachments.isNotEmpty) {
        attachmentUrls = await FileUploadService.uploadFiles(
          _pendingAttachments,
          context: 'support',
          uploadPath: '/v1/support/upload',
        );
      }
      await SupportApi.addMessage(
        widget.ticketId,
        text.isEmpty ? 'Attachment' : text,
        attachments: attachmentUrls,
      );
      _messageController.clear();
      setState(() => _pendingAttachments = []);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submitRating() async {
    setState(() => _rating = true);
    try {
      await SupportApi.rateSatisfaction(
        widget.ticketId,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _rating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5F2D82),
        title: Text(
          _detail?.ticket.subject ?? 'Ticket',
          style: const TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
          : _error != null
              ? RetryWidget(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                        itemCount: _detail!.messages.length,
                        itemBuilder: (context, index) {
                          final msg = _detail!.messages[index];
                          final isMine = !msg.isStaff;
                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? const Color(0xFF5F2D82)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (msg.message.isNotEmpty)
                                    Text(
                                      msg.message,
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        color: isMine ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  if (msg.attachments.isNotEmpty) ...[
                                    if (msg.message.isNotEmpty)
                                      const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: msg.attachments.map((url) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            url,
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_detail!.canRateSatisfaction)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Rate support experience',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final star = index + 1;
                                return IconButton(
                                  onPressed: () =>
                                      setState(() => _selectedRating = star),
                                  icon: Icon(
                                    star <= _selectedRating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: const Color(0xFFFFB300),
                                  ),
                                );
                              }),
                            ),
                            TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                labelText: 'Optional comment',
                              ),
                            ),
                            FilledButton(
                              onPressed: _rating ? null : _submitRating,
                              child: _rating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Submit rating'),
                            ),
                          ],
                        ),
                      ),
                    if (_pendingAttachments.isNotEmpty)
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _pendingAttachments.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final file = _pendingAttachments[index];
                            return Chip(
                              label: Text(
                                file.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onDeleted: () {
                                setState(() {
                                  _pendingAttachments.removeAt(index);
                                });
                              },
                            );
                          },
                        ),
                      ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _sending ? null : _pickAttachments,
                              icon: const Icon(Icons.attach_file),
                              color: const Color(0xFF5F2D82),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Write a message…',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              style: const ButtonStyle(
                                backgroundColor:
                                    WidgetStatePropertyAll(Color(0xFF5F2D82)),
                              ),
                              onPressed: _sending ? null : _sendMessage,
                              icon: _sending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
