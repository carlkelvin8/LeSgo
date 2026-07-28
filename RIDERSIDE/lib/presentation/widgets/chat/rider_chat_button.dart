import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/chat/chat_provider.dart';
import '../../screens/chat/rider_chat_screen.dart';

class RiderChatButton extends ConsumerWidget {
  final int orderId;
  final String? customerName;

  const RiderChatButton({
    super.key,
    required this.orderId,
    this.customerName,
  });

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiderChatScreen(
          orderId: orderId,
          customerName: customerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5F2D82),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChat(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  customerName != null
                      ? 'Chat with $customerName'
                      : 'Chat with Customer',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating action button version for booking detail screens
/// Shows unread badge and triggers notification sound when new messages arrive.
class FloatingRiderChatButton extends ConsumerStatefulWidget {
  final int orderId;
  final String? customerName;

  const FloatingRiderChatButton({
    super.key,
    required this.orderId,
    this.customerName,
  });

  @override
  ConsumerState<FloatingRiderChatButton> createState() =>
      _FloatingRiderChatButtonState();
}

class _FloatingRiderChatButtonState
    extends ConsumerState<FloatingRiderChatButton> {
  int _unreadCount = 0;
  int _lastKnownCount = 0;
  late final _pollTimer = Stream.periodic(const Duration(seconds: 5));
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _mounted = false;
    // Clear any lingering snackbars from this widget
    try {
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    } catch (_) {}
    super.dispose();
  }

  void _startPolling() async {
    // Initial check
    await _checkUnread();
    // Then poll every 5 seconds
    await for (final _ in _pollTimer) {
      if (!_mounted) break;
      await _checkUnread();
    }
  }

  Future<void> _checkUnread() async {
    if (!_mounted) return;
    try {
      final chatNotifier = ref.read(chatProviderFamily(widget.orderId).notifier);
      await chatNotifier.loadUnreadCount();
      final chatState = ref.read(chatProviderFamily(widget.orderId));
      if (!_mounted) return;

      final newCount = chatState.unreadCount;
      if (newCount > _lastKnownCount && _lastKnownCount >= 0) {
        // New message arrived — show in-app notification
        if (newCount > 0 && mounted) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger != null) {
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💬 New message from ${widget.customerName ?? "customer"}',
                        style: const TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF5F2D82),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                dismissDirection: DismissDirection.horizontal,
                action: SnackBarAction(
                  label: 'Open',
                  textColor: Colors.white,
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    if (mounted) _openChat(context);
                  },
                ),
              ),
            );
          }
        }
      }
      _lastKnownCount = newCount;
      if (mounted) {
        setState(() => _unreadCount = newCount);
      }
    } catch (_) {}
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiderChatScreen(
          orderId: widget.orderId,
          customerName: widget.customerName,
        ),
      ),
    ).then((_) {
      // Reset unread after coming back from chat
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _lastKnownCount = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          heroTag: 'chat_fab_${widget.orderId}',
          onPressed: () => _openChat(context),
          backgroundColor: const Color(0xFF5F2D82),
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
