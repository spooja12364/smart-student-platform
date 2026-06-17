import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_student_platform/theme.dart';

class GlobalGroupChat extends StatefulWidget {
  const GlobalGroupChat({super.key});

  @override
  State<GlobalGroupChat> createState() => _GlobalGroupChatState();
}

class _GlobalGroupChatState extends State<GlobalGroupChat> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _chatRef = FirebaseDatabase.instance.ref("groupChat");
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    if (currentUser == null) return;
    final snapshot = await FirebaseDatabase.instance.ref("users/${currentUser!.uid}").once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _userName = data['name'] ?? currentUser!.email?.split('@').first ?? "User";
      });
    } else {
      setState(() {
        _userName = currentUser!.email?.split('@').first ?? "User";
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || currentUser == null) return;

    final newMessageRef = _chatRef.push();
    newMessageRef.set({
      "messageId": newMessageRef.key,
      "uid": currentUser!.uid,
      "sender": _userName,
      "message": _messageController.text.trim(),
      "timestamp": ServerValue.timestamp,
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.cardDark,
          width: double.infinity,
          child: const Text(
            "Global Collaboration Chat",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: _chatRef.orderByChild('timestamp').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
              }

              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return const Center(child: Text("No messages yet. Start the conversation!", style: TextStyle(color: AppTheme.textGray)));
              }

              Map<dynamic, dynamic> messagesMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List<dynamic> messages = messagesMap.values.toList();
              messages.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
              
              // Scroll to bottom after rebuild
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final bool isMe = msg['uid'] == currentUser?.uid;

                  final timestamp = msg['timestamp'];
                  final DateTime? time = timestamp is int ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
                  final String timeString = time != null ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : '';

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primaryPurple : AppTheme.cardDark,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                        ),
                      ),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              msg['sender'] ?? 'Unknown',
                              style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            msg['message'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          if (timeString.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              timeString,
                              style: TextStyle(color: AppTheme.textGray.withOpacity(0.9), fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.cardDark,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: const TextStyle(color: AppTheme.textGray),
                    filled: true,
                    fillColor: AppTheme.darkBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryPurple,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
