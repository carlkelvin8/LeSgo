import 'package:flutter/material.dart';

/// Result of the report sheet: the chosen reason, optional details and
/// whether the reporter also wants to block the other person.
class ChatReportResult {
  final String reason;
  final String? details;
  final bool block;

  const ChatReportResult({
    required this.reason,
    this.details,
    required this.block,
  });
}

/// Bottom sheet for reporting objectionable chat content
/// (App Store Guideline 1.2).
class ChatReportSheet extends StatefulWidget {
  final String targetLabel;
  final bool isMessage;

  const ChatReportSheet({
    super.key,
    required this.targetLabel,
    this.isMessage = false,
  });

  static Future<ChatReportResult?> show(
    BuildContext context, {
    required String targetLabel,
    bool isMessage = false,
  }) {
    return showModalBottomSheet<ChatReportResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChatReportSheet(
        targetLabel: targetLabel,
        isMessage: isMessage,
      ),
    );
  }

  @override
  State<ChatReportSheet> createState() => _ChatReportSheetState();
}

class _ChatReportSheetState extends State<ChatReportSheet> {
  static const _reasons = <String, String>{
    'harassment': 'Harassment or bullying',
    'hate_speech': 'Hate speech',
    'sexual_content': 'Sexual or inappropriate content',
    'threats_or_violence': 'Threats or violence',
    'spam_or_scam': 'Spam or scam',
    'other': 'Something else',
  };

  final TextEditingController _detailsController = TextEditingController();
  String? _reason;
  bool _block = true;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isMessage
                    ? 'Report message'
                    : 'Report ${widget.targetLabel}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Your report is confidential. Our team reviews every report within 24 hours.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: _reasons.entries
                      .map((e) => RadioListTile<String>(
                            value: e.key,
                            title: Text(e.value),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF5F2D82),
                          ))
                      .toList(),
                ),
              ),
              TextField(
                controller: _detailsController,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'Add details (optional)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              CheckboxListTile(
                value: _block,
                onChanged: (v) => setState(() => _block = v ?? false),
                title: Text('Also block ${widget.targetLabel}'),
                subtitle: const Text('You will no longer exchange messages.'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF5F2D82),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _reason == null
                      ? null
                      : () => Navigator.pop(
                            context,
                            ChatReportResult(
                              reason: _reason!,
                              details: _detailsController.text.trim(),
                              block: _block,
                            ),
                          ),
                  child: const Text('Submit report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
