import 'package:fe/src/feature/grade_ui/data/ai_chat_api_service.dart';
import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';
import 'package:flutter/material.dart';

class AiPannelCard extends StatefulWidget {
  const AiPannelCard({
    super.key,
    required this.onStudentsFound,
    this.baseUrl = 'http://localhost:8080',
  });

  final String baseUrl;
  final ValueChanged<List<StudentGrade>> onStudentsFound;

  @override
  State<AiPannelCard> createState() => _AiPannelCardState();
}

class _AiPannelCardState extends State<AiPannelCard> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatEntry> _messages = [];

  late final AiChatApiService _api = AiChatApiService(baseUrl: widget.baseUrl);

  bool _isSending = false;

  @override
  void dispose() {
    _api.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatEntry(text: message, isUser: true));
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final result = await _api.ask(message);
      if (!mounted) return;

      setState(() {
        _messages.add(_ChatEntry(text: result.message, isUser: false));
      });
      if (result.students.isNotEmpty) {
        widget.onStudentsFound(result.students);
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(_ChatEntry(text: 'AI chat error: $e', isUser: false));
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "AI Chat Bot",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Ask about your grade data.\nExample: "How many students passed?"',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _ChatBubble(entry: _messages[index]);
                      },
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isSending,
                    decoration: const InputDecoration(
                      hintText: 'Enter your question...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),

                IconButton.filled(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEntry {
  const _ChatEntry({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.entry});

  final _ChatEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: entry.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: entry.isUser ? colors.primary : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SelectableText(
              entry.text,
              style: TextStyle(
                color: entry.isUser
                    ? colors.onPrimary
                    : const Color(0xFF111827),
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
