import 'package:lesgo/core/theme/app_colors.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/main/support/customer_service_chat_provider.dart';
import '../../../widgets/support/customer_service_message_bubble.dart';
import '../../../widgets/support/ibow_orbit_avatar.dart';
import '../../../../domain/entities/support/ibow_expression.dart';

class CustomerServiceChatScreen extends ConsumerStatefulWidget {
  const CustomerServiceChatScreen({super.key});

  @override
  ConsumerState<CustomerServiceChatScreen> createState() =>
      _CustomerServiceChatScreenState();
}

class _CustomerServiceChatScreenState
    extends ConsumerState<CustomerServiceChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  FlutterTts? _speech;
  int _speechRequest = 0;
  String? _spokenMessageId;
  Timer? _speakTimer;
  Timer? _hintTimer;
  Timer? _moodTimer;
  Timer? _idleTimer;
  bool _speaking = false;
  bool get _isSpeaking => _speaking || _spokenMessageId != null;
  IbowExpression _expression = IbowExpression.neutral;
  bool _typing = false;
  bool _popoverOpen = false;
  bool _hintVisible = false;
  bool _dragging = false;

  /// Top-left of the floating IBOW inside the chat area; null = docked
  /// bottom-right (the default).
  Offset? _ibowOffset;

  static const _ibowSize = 92.0;
  // Things IBOW can actually do for you, not just explain.
  static const _quickQuestions = [
    'Where is my order?',
    'Cancel my order',
    'Order again',
    'My LesPay balance',
    'Place an order',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final typing = _controller.text.trim().isNotEmpty;
      _wake();
      if (typing != _typing && mounted) setState(() => _typing = typing);
    });
    _scheduleIdle();
  }

  /// Shows [mood] on IBOW's face for a few seconds, then back to neutral.
  void _showMood(IbowExpression? mood) {
    if (mood == null) return;
    _moodTimer?.cancel();
    setState(() => _expression = mood);
    if (mood == IbowExpression.neutral) return;
    _moodTimer = Timer(const Duration(milliseconds: 4200), () {
      if (mounted) setState(() => _expression = IbowExpression.neutral);
    });
  }

  /// Any activity wakes IBOW up; 45 quiet seconds send it to sleep.
  void _wake() {
    if (_expression == IbowExpression.sleepy && mounted) {
      setState(() => _expression = IbowExpression.neutral);
    }
    _scheduleIdle();
  }

  void _scheduleIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 45), () {
      if (mounted && _expression == IbowExpression.neutral) {
        setState(() => _expression = IbowExpression.sleepy);
      }
    });
  }

  /// IBOW "talks" (mouth + arms) for a moment after each reply arrives.
  void _speakFor(String text) {
    _speakTimer?.cancel();
    final ms = (700 + text.length * 22).clamp(900, 3800);
    setState(() => _speaking = true);
    _speakTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      setState(() {
        _speaking = false;
        _hintVisible = true;
      });
      // A small "anything else?" pop-up next to IBOW, then it tucks away.
      _hintTimer?.cancel();
      _hintTimer = Timer(const Duration(milliseconds: 3600), () {
        if (mounted) setState(() => _hintVisible = false);
      });
    });
  }

  Future<void> _stopSpeech() async {
    _speechRequest++;
    if (mounted && _spokenMessageId != null) {
      setState(() => _spokenMessageId = null);
    }
    try {
      await _speech?.stop();
    } catch (error) {
      debugPrint('Ibow speech could not stop: ${error.runtimeType}');
    }
  }

  Future<void> _toggleSpeech(CustomerServiceMessage message) async {
    if (_spokenMessageId == message.id) {
      await _stopSpeech();
      return;
    }

    final request = ++_speechRequest;
    final speech = _speech ??= FlutterTts();
    _wake();
    setState(() => _spokenMessageId = message.id);
    try {
      await speech.stop();
      if (!mounted || request != _speechRequest) return;
      await speech.awaitSpeakCompletion(true);
      if (!mounted || request != _speechRequest) return;
      final result = await speech.speak(message.text.replaceAll('• ', ''));
      if (result != 1) throw StateError('Speech could not play');
    } catch (_) {
      if (mounted && request == _speechRequest) {
        SnackBarUtils.showError(
          context,
          'Ibow voice is unavailable right now.',
        );
      }
    } finally {
      if (mounted && request == _speechRequest) {
        setState(() => _spokenMessageId = null);
      }
    }
  }

  Future<void> _sendSuggestion(String text) async {
    final chat = ref.read(customerServiceChatProvider);
    if (chat.isSending) return;
    if (!chat.isConfigured) {
      SnackBarUtils.showError(
        context,
        'Support chat is currently unavailable. Please use "Talk to human support".',
      );
      return;
    }
    setState(() {
      _popoverOpen = false;
      _hintVisible = false;
    });
    await ref.read(customerServiceChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _spokenMessageId = null;
    unawaited(_stopSpeech());
    _speakTimer?.cancel();
    _hintTimer?.cancel();
    _moodTimer?.cancel();
    _idleTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final chat = ref.read(customerServiceChatProvider);
    if (chat.isSending) return;

    if (!chat.isConfigured) {
      SnackBarUtils.showError(
        context,
        'Support chat is currently unavailable. Please use "Talk to human support".',
      );
      return;
    }

    _controller.clear();
    await ref.read(customerServiceChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(customerServiceChatProvider);
    ref.listen(customerServiceChatProvider, (previous, next) {
      _scrollToBottom();
      final grew = next.messages.length > (previous?.messages.length ?? 0);
      // Only speak for replies that arrive after the opening greeting.
      if (grew &&
          (previous?.messages.isNotEmpty ?? false) &&
          !next.messages.last.isUser) {
        _speakFor(next.messages.last.text);
        _showMood(next.messages.last.mood);
        _scheduleIdle();
      }
    });
    final showHero = chatState.messages.length <= 1;

    return Listener(
      onPointerDown: (_) => _wake(),
      child: Scaffold(
        backgroundColor: AppColors.surface(context, Colors.white),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              IbowOrbitAvatar(
                size: 54,
                isThinking: chatState.isSending,
                isSpeaking: _isSpeaking,
                expression: _expression,
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 10)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IBOW',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chatState.isConfigured) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2E9E5B),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        chatState.isConfigured
                            ? 'LeSgo AI · Online'
                            : (kDebugMode ? 'Setup required' : 'Live support'),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 11.5),
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'human':
                    unawaited(_stopSpeech());
                    AppRouter.push(context, MainRoutes.supportTickets);
                    break;
                  case 'clear':
                    unawaited(_stopSpeech());
                    ref.read(customerServiceChatProvider.notifier).clearChat();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'human',
                  child: Text('Talk to human support'),
                ),
                PopupMenuItem(value: 'clear', child: Text('Clear chat')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            if (!chatState.isConfigured)
              Container(
                width: double.infinity,
                color: AppColors.surface(context, const Color(0xFFFFF8E1)),
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                child: Text(
                  'AI replies are temporarily unavailable. Please use "Talk to human support".',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: AppColors.foreground(
                      context,
                      Colors.orange.shade900,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: _messageList(chatState, showHero)),
                    ..._floatingIbow(context, box, chatState, showHero),
                  ],
                ),
              ),
            ),
            if (chatState.error != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 16),
                  vertical: ResponsiveUtils.spacing(context, 4),
                ),
                child: Text(
                  chatState.error!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            _inputBar(context, chatState.isSending),
          ],
        ),
      ),
    );
  }

  Widget _messageList(CustomerServiceChatState chatState, bool showHero) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: ResponsiveUtils.spacing(context, 12),
        bottom: showHero ? 12 : 108,
      ),
      itemCount:
          (showHero ? 1 : 0) +
          chatState.messages.length +
          (chatState.isSending ? 1 : 0),
      itemBuilder: (context, rawIndex) {
        if (showHero && rawIndex == 0) {
          return _hero(context, chatState.isSending);
        }
        final index = rawIndex - (showHero ? 1 : 0);
        if (index >= chatState.messages.length) {
          return _typingIndicator(context);
        }
        final message = chatState.messages[index];
        return CustomerServiceMessageBubble(
          message: message,
          isPlayingSpeech: _spokenMessageId == message.id,
          onToggleSpeech: () => unawaited(_toggleSpeech(message)),
          statusOf: (a) => chatState.statusOf(message.id, a.id),
          onRunAction: (a) => ref
              .read(customerServiceChatProvider.notifier)
              .runAction(message.id, a),
          onDismissActions: () => ref
              .read(customerServiceChatProvider.notifier)
              .dismissActions(message.id),
          onOpenLink: (link) {
            unawaited(_stopSpeech());
            AppRouter.push(context, link.route);
          },
        );
      },
    );
  }

  /// IBOW as a pop-up companion: it bounces in once the conversation starts,
  /// can be dragged (snaps to the nearest side), looks down at the text field
  /// while you type, thinks while waiting, talks when a reply lands, and a tap
  /// opens a pop-over of quick questions.
  List<Widget> _floatingIbow(
    BuildContext context,
    BoxConstraints box,
    CustomerServiceChatState chatState,
    bool showHero,
  ) {
    const size = _ibowSize;
    const margin = 10.0;
    Offset clamp(Offset o) => Offset(
      o.dx.clamp(4.0, box.maxWidth - size - 4),
      o.dy.clamp(4.0, box.maxHeight - size - 4),
    );
    final home = Offset(box.maxWidth - size - margin, box.maxHeight - size - 6);
    final pos = clamp(_ibowOffset ?? home);
    final onRight = pos.dx + size / 2 > box.maxWidth / 2;
    final roomAbove = pos.dy > 210;
    final visible = !showHero;

    final avatar = AnimatedPositioned(
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      left: pos.dx,
      top: pos.dy,
      width: size,
      height: size,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedScale(
          scale: visible ? 1 : 0,
          alignment: Alignment.bottomCenter,
          duration: Duration(milliseconds: visible ? 750 : 200),
          curve: visible ? Curves.elasticOut : Curves.easeIn,
          child: GestureDetector(
            onPanStart: (_) => setState(() {
              _dragging = true;
              _popoverOpen = false;
              _hintVisible = false;
            }),
            onPanUpdate: (d) => setState(
              () => _ibowOffset = clamp((_ibowOffset ?? home) + d.delta),
            ),
            onPanEnd: (_) => setState(() {
              final p = clamp(_ibowOffset ?? home);
              _dragging = false;
              _ibowOffset = Offset(
                p.dx + size / 2 > box.maxWidth / 2
                    ? box.maxWidth - size - margin
                    : margin,
                p.dy,
              );
            }),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8E4DC3).withValues(alpha: 0.28),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IbowOrbitAvatar(
                size: size,
                isThinking: chatState.isSending,
                isSpeaking: _isSpeaking,
                expression: _expression,
                lookDirection: _typing ? const Offset(0.1, 0.95) : null,
                onTap: () => setState(() {
                  _popoverOpen = !_popoverOpen;
                  _hintVisible = false;
                }),
              ),
            ),
          ),
        ),
      ),
    );

    // Pop-over with quick questions / small "anything else?" hint.
    final showCard = visible && (_popoverOpen || _hintVisible);
    final cardAlignment = roomAbove
        ? (onRight ? Alignment.bottomRight : Alignment.bottomLeft)
        : (onRight ? Alignment.topRight : Alignment.topLeft);
    final card = Positioned(
      left: onRight ? null : pos.dx,
      right: onRight ? box.maxWidth - (pos.dx + size) : null,
      bottom: roomAbove ? box.maxHeight - pos.dy + 6 : null,
      top: roomAbove ? null : pos.dy + size + 6,
      child: IgnorePointer(
        ignoring: !showCard,
        child: AnimatedScale(
          scale: showCard ? 1 : 0,
          alignment: cardAlignment,
          duration: const Duration(milliseconds: 320),
          curve: showCard ? Curves.easeOutBack : Curves.easeIn,
          child: AnimatedOpacity(
            opacity: showCard ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: _popoverOpen
                ? _quickQuestionsCard(context)
                : _hintCard(context),
          ),
        ),
      ),
    );

    return [card, avatar];
  }

  Widget _hintCard(BuildContext context) {
    return Material(
      color: AppColors.surface(context, Colors.white),
      elevation: 6,
      shadowColor: const Color(0xFF5F2D82).withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          'Anything else I can help with? 💜',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w600,
            color: AppColors.foreground(context, Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _quickQuestionsCard(BuildContext context) {
    return Material(
      color: AppColors.surface(context, Colors.white),
      elevation: 8,
      shadowColor: const Color(0xFF5F2D82).withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi! What do you need?',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final q in _quickQuestions)
                    _pill(context, q, () => _sendSuggestion(q), small: true),
                  ActionChip(
                    avatar: const Icon(Icons.support_agent, size: 16),
                    label: const Text('Talk to a human'),
                    onPressed: () {
                      setState(() => _popoverOpen = false);
                      AppRouter.push(context, MainRoutes.supportTickets);
                    },
                    side: BorderSide.none,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A tappable suggestion: white pill, lilac outline, soft shadow.
  Widget _pill(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    bool small = false,
  }) {
    final accent = AppColors.accent(context, const Color(0xFF5F2D82));
    return Material(
      color: AppColors.surface(context, Colors.white),
      elevation: 1.5,
      shadowColor: accent.withValues(alpha: 0.25),
      shape: StadiumBorder(
        side: BorderSide(color: accent.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 12 : 16,
            vertical: small ? 8 : 11,
          ),
          child: Text(
            label,
            style: ChatType.chip(context).copyWith(
              fontSize: ResponsiveUtils.fontSize(context, small ? 12 : 13.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Big animated IBOW with suggested questions, shown until the user chats.
  Widget _hero(BuildContext context, bool isSending) {
    const suggestions = _quickQuestions;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.spacing(context, 16),
        ResponsiveUtils.spacing(context, 8),
        ResponsiveUtils.spacing(context, 16),
        ResponsiveUtils.spacing(context, 8),
      ),
      child: Column(
        children: [
          IbowOrbitAvatar(
            size: 180,
            isThinking: isSending,
            isSpeaking: _isSpeaking,
            expression: _expression,
            lookDirection: _typing ? const Offset(0.1, 0.95) : null,
          ),
          const SizedBox(height: 4),
          Text(
            'Hi, I’m IBOW!',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 24),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.foreground(context, const Color(0xFF2A1B38)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap me, or ask about your orders, LesPay and vouchers.',
            textAlign: TextAlign.center,
            style: ChatType.body(
              context,
              size: 13.5,
              color: AppColors.foreground(context, Colors.grey[600]!),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in suggestions)
                _pill(context, q, () => _sendSuggestion(q)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typingIndicator(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 4),
      ),
      child: Row(
        children: [
          const IbowOrbitAvatar(size: 36, isThinking: true),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface(context, Colors.white),
              border: Border.all(
                color: AppColors.border(context, const Color(0xFFE6E3EA)),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(BuildContext context, bool isSending) {
    final accent = AppColors.accent(context, const Color(0xFF5F2D82));
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtils.spacing(context, 14),
          ResponsiveUtils.spacing(context, 8),
          ResponsiveUtils.spacing(context, 14),
          ResponsiveUtils.spacing(context, 12),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          decoration: BoxDecoration(
            color: AppColors.surface(context, Colors.white),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.border(context, const Color(0xFFE9DDF5)),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5F2D82).withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !isSending,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: accent,
                  onSubmitted: (_) => _send(),
                  style: ChatType.body(context),
                  decoration: InputDecoration(
                    hintText: 'Message IBOW…',
                    hintStyle: ChatType.body(
                      context,
                      color: AppColors.foreground(
                        context,
                        Colors.grey.shade500,
                      ),
                    ),
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.spacing(context, 16),
                      vertical: ResponsiveUtils.spacing(context, 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Opacity(
                opacity: isSending ? 0.55 : 1,
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7A3FB0), Color(0xFF4F2270)],
                      ),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: isSending ? null : _send,
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three dots that bob in turn while IBOW is replying.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.accent(context, const Color(0xFF5F2D82));
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
              child: Transform.translate(
                offset: Offset(0, -4 * _bob((_c.value - i * 0.16) % 1)),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(
                      alpha: 0.35 + 0.65 * _bob((_c.value - i * 0.16) % 1),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 0 -> 1 -> 0 over the first half of the cycle, then rests.
  double _bob(double t) => t < 0.5 ? (1 - (2 * t - 1).abs()) : 0;
}
