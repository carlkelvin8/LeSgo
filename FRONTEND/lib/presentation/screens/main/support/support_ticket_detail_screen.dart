import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../data/data_source/support_remote_datasource.dart';
import '../../../widgets/widgets.dart';

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final _messageController = TextEditingController();
  final _commentController = TextEditingController();
  final _dataSource = getIt<SupportRemoteDataSource>();
  final _uploadService = getIt<FileUploadService>();
  final _picker = ImagePicker();
  SupportTicketDetail? _detail;
  bool _loading = true;
  bool _sending = false;
  bool _rating = false;
  int _selectedRating = 5;
  String? _error;
  final List<XFile> _pendingAttachments = [];

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
      final detail = await _dataSource.getTicket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load ticket.',
          fallbackTl: 'Hindi ma-load ang ticket.',
        );
        _loading = false;
      });
    }
  }

  Future<void> _pickAttachments() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      _pendingAttachments
        ..clear()
        ..addAll(files.take(3));
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;
    setState(() => _sending = true);
    try {
      List<String>? attachmentUrls;
      if (_pendingAttachments.isNotEmpty) {
        attachmentUrls = await _uploadService.uploadFiles(
          _pendingAttachments,
          context: 'support',
          uploadPath: ApiConstants.supportUpload,
        );
      }
      await _dataSource.addMessage(
        widget.ticketId,
        text.isEmpty ? 'Attachment shared' : text,
        attachments: attachmentUrls,
      );
      _messageController.clear();
      _pendingAttachments.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorMapper.message(
                e,
                fallbackEn: 'Failed to send message.',
                fallbackTl: 'Hindi ma-send ang mensahe.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submitRating() async {
    setState(() => _rating = true);
    try {
      await _dataSource.rateSatisfaction(
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
          SnackBar(
            content: Text(
              ApiErrorMapper.message(
                e,
                fallbackEn: 'Could not submit rating.',
                fallbackTl: 'Hindi ma-submit ang rating.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _rating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: AuthHeader(title: _detail?.ticket.subject ?? 'Ticket'),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
                    )
                  : _error != null
                      ? Center(child: Text(_error!))
                      : Column(
                          children: [
                            if (_detail!.canRateSatisfaction)
                              _SatisfactionCard(
                                selectedRating: _selectedRating,
                                commentController: _commentController,
                                submitting: _rating,
                                onRatingChanged: (value) =>
                                    setState(() => _selectedRating = value),
                                onSubmit: _submitRating,
                              )
                            else if (_detail!.satisfactionRating != null)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.spacing(context, 16),
                                ),
                                child: Text(
                                  'Your rating: ${_detail!.satisfactionRating}/5',
                                  style: const TextStyle(fontFamily: 'TT Fors'),
                                ),
                              ),
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.all(
                                  ResponsiveUtils.spacing(context, 16),
                                ),
                                itemCount: _detail!.messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _detail!.messages[index];
                                  return Align(
                                    alignment: msg.isStaff
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        bottom: ResponsiveUtils.spacing(
                                          context,
                                          8,
                                        ),
                                      ),
                                      padding: EdgeInsets.all(
                                        ResponsiveUtils.spacing(context, 12),
                                      ),
                                      decoration: BoxDecoration(
                                        color: msg.isStaff
                                            ? Colors.grey.shade100
                                            : const Color(0xFF5F2D82)
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        msg.message,
                                        style: TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontSize: ResponsiveUtils.fontSize(
                                            context,
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_pendingAttachments.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${_pendingAttachments.length} attachment(s) ready to send',
                                    style: const TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.all(
                                ResponsiveUtils.spacing(context, 12),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: _sending ? null : _pickAttachments,
                                    icon: const Icon(Icons.attach_file),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: const InputDecoration(
                                        hintText: 'Write a reply...',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _sending ? null : _sendMessage,
                                    icon: _sending
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.send),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
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
                    color: const Color(0xFF5F2D82),
                  ),
                );
              }),
            ),
            TextField(
              controller: commentController,
              enabled: !submitting,
              decoration: const InputDecoration(
                labelText: 'Optional comment',
              ),
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
