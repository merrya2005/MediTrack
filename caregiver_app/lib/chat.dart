import 'package:flutter/material.dart';
import 'package:caregiver_app/main.dart';

class ChatScreen extends StatefulWidget {
  final int patientId;
  final String patientName;
  final int caregiverId;

  const ChatScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.caregiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Color _primaryColor = const Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _markMessagesAsSeen();
  }

  void _markMessagesAsSeen() async {
    try {
      await supabase
          .from('tbl_chat')
          .update({'chat_isseen': 1})
          .eq('chat_tocaregiver', widget.caregiverId)
          .eq('chat_frompatient', widget.patientId);
    } catch (e) {
      debugPrint("Mark seen error: $e");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final caregiverId = widget.caregiverId;
    final patientId = widget.patientId;

    _messageController.clear();

    try {
      await supabase.from('tbl_chat').insert({
        'chat_content': text,
        'chat_fromcaregiver': caregiverId,
        'chat_topatient': patientId,
        'chat_isseen': 0,
      });
      // Scroll will happen automatically via Stream & PostFrameCallback
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    try {
      await supabase.from('tbl_chat').delete().eq('id', messageId);
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  Future<void> _clearChat() async {
    try {
      await supabase
          .from('tbl_chat')
          .delete()
          .or('and(chat_fromcaregiver.eq.${widget.caregiverId},chat_topatient.eq.${widget.patientId}),and(chat_frompatient.eq.${widget.patientId},chat_tocaregiver.eq.${widget.caregiverId})');
    } catch (e) {
      debugPrint("Error clearing chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Clear Chat"),
                    content: const Text("Are you sure you want to delete all messages?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      TextButton(onPressed: () {
                        _clearChat();
                        Navigator.pop(context);
                      }, child: const Text("Clear", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear', child: Text("Clear Chat")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Simplified stream call to maximize real-time reliability
              stream: supabase.from('tbl_chat').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Connection lost."));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final allMessages = snapshot.data!;
                // Ensure correct chronological order manually
                allMessages.sort((a, b) => (a['created_at'] ?? "").compareTo(b['created_at'] ?? ""));

                final messages = allMessages.where((m) {
                  return (m['chat_fromcaregiver'] == widget.caregiverId && m['chat_topatient'] == widget.patientId) ||
                         (m['chat_frompatient'] == widget.patientId && m['chat_tocaregiver'] == widget.caregiverId);
                }).toList();

                if (messages.isEmpty) return const Center(child: Text("Start the conversation!"));

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                  final hasUnread = messages.any((m) => m['chat_frompatient'] == widget.patientId && m['chat_isseen'] == 0);
                  if (hasUnread) _markMessagesAsSeen();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['chat_fromcaregiver'] == widget.caregiverId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Message"),
                              content: const Text("Are you sure you want to delete this message?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                TextButton(onPressed: () {
                                  _deleteMessage(msg['id']);
                                  Navigator.pop(context);
                                }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? _primaryColor : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 16),
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                          ),
                          child: Text(msg['chat_content'] ?? "", style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Type something...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
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
