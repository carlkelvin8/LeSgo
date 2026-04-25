import 'package:flutter/material.dart';

import '../../../core/utils/responsive_utils.dart';

class ChatInputWidget extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback? onSendLocation;
  final bool isLoading;
  final bool enabled;

  const ChatInputWidget({
    super.key,
    required this.onSendMessage,
    this.onSendLocation,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    if (!_hasText || widget.isLoading || !widget.enabled) return;
    
    final message = _controller.text.trim();
    _controller.clear();
    widget.onSendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Location button
            if (widget.onSendLocation != null)
              IconButton(
                onPressed: widget.enabled ? widget.onSendLocation : null,
                icon: Icon(
                  Icons.location_on,
                  color: widget.enabled ? const Color(0xFF5F2D82) : Colors.grey[400],
                ),
                tooltip: 'Share location',
              ),
            
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.spacing(context, 16),
                      vertical: ResponsiveUtils.spacing(context, 12),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            
            // Send button
            Container(
              decoration: BoxDecoration(
                color: _hasText && widget.enabled ? const Color(0xFF5F2D82) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _hasText && widget.enabled && !widget.isLoading ? _sendMessage : null,
                icon: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _hasText ? Colors.white : Colors.grey[600]!,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: _hasText && widget.enabled ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}