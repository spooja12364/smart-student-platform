import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:smart_student_platform/src/file_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String? otherUserName;

  const ChatDetailPage({super.key, required this.chatId, required this.otherUserId, this.otherUserName});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _msgController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage({String? text}) async {
    if (text == null || text.trim().isEmpty) return;

    final msgText = text.trim();
    _msgController.clear();

    try {
      // Create/Update the chat document FIRST so it exists for security rules
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'lastMessage': msgText,
        'lastUpdated': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayUnion([user?.uid, widget.otherUserId]),
      }, SetOptions(merge: true));

      // THEN add the message
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add({
        'senderId': user?.uid,
        'text': msgText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: const Text('Send Failed', style: TextStyle(color: Colors.white)),
            content: Text('Database Error: $e\n\nPlease check your Firestore Rules.', style: const TextStyle(color: AppTheme.textGray)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: AppTheme.primaryPurple))),
            ],
          ),
        );
      }
    }
  }



  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          title: const Text('Chat', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.cardDark,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('Please sign in to use chat.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return FutureBuilder<DatabaseEvent>(
      future: FirebaseDatabase.instance.ref('users/${widget.otherUserId}').once(),
      builder: (context, userSnapshot) {
        final otherUserName = userSnapshot.hasData && userSnapshot.data!.snapshot.value != null
            ? ((Map<dynamic, dynamic>.from(userSnapshot.data!.snapshot.value as Map))['fullName'] ??
               (Map<dynamic, dynamic>.from(userSnapshot.data!.snapshot.value as Map))['name'] ??
               widget.otherUserName ?? 'Connected user')
            : (widget.otherUserName ?? 'Connected user');

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppTheme.darkBg,
          appBar: AppBar(
            title: Text('Chat with $otherUserName', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.cardDark,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No messages yet. Start the conversation.', style: TextStyle(color: AppTheme.textGray)));
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final bool isMe = data['senderId'] == user?.uid;
                      final String? imageUrl = data['imageUrl'];
                      final String? text = data['text'];
                      final String? fileUrl = data['fileUrl'];

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: isMe
                              ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: AppTheme.cardDark,
                                    builder: (context) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          if (text != null && text.isNotEmpty)
                                            ListTile(
                                              leading: const Icon(Icons.edit, color: Colors.white),
                                              title: const Text('Edit Message', style: TextStyle(color: Colors.white)),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _msgController.text = text;
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    final editController = TextEditingController(text: text);
                                                    return AlertDialog(
                                                      backgroundColor: AppTheme.cardDark,
                                                      title: const Text('Edit Message', style: TextStyle(color: Colors.white)),
                                                      content: TextField(
                                                        controller: editController,
                                                        style: const TextStyle(color: Colors.white),
                                                        decoration: const InputDecoration(
                                                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryPurple)),
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: const Text('Cancel', style: TextStyle(color: AppTheme.textGray)),
                                                        ),
                                                        TextButton(
                                                          onPressed: () async {
                                                            if (editController.text.trim().isNotEmpty) {
                                                              await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').doc(docs[index].id).update({
                                                                'text': editController.text.trim(),
                                                                'isEdited': true,
                                                              });
                                                            }
                                                            if (mounted) Navigator.pop(context);
                                                          },
                                                          child: const Text('Save', style: TextStyle(color: AppTheme.primaryPurple)),
                                                        ),
                                                      ],
                                                    );
                                                  }
                                                );
                                              },
                                            ),
                                          ListTile(
                                            leading: const Icon(Icons.delete, color: Colors.redAccent),
                                            title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent)),
                                            onTap: () async {
                                              Navigator.pop(context);
                                              await _deleteMessage(docs[index].id);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message deleted')));
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(imageUrl != null ? 4 : 12),
                            decoration: BoxDecoration(
                              color: isMe ? AppTheme.primaryBlue : AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: isMe ? const Radius.circular(0) : null,
                                bottomLeft: !isMe ? const Radius.circular(0) : null,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      width: 200,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const SizedBox(width: 200, height: 200, child: Center(child: CircularProgressIndicator(color: Colors.white)));
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 200,
                                          height: 200,
                                          color: Colors.grey[800],
                                          child: const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.error_outline, color: Colors.white, size: 40),
                                                SizedBox(height: 8),
                                                Text('Could not load image\n(CORS/Permissions)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                if (fileUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: InkWell(
                                      onTap: () async {
                                        final uri = Uri.parse(fileUrl);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.attach_file, color: Colors.white, size: 24),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              text ?? 'Download file',
                                              style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 15, decoration: TextDecoration.underline),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (text != null && text.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: imageUrl != null ? 8 : 0, left: imageUrl != null ? 8 : 0, right: imageUrl != null ? 8 : 0, bottom: imageUrl != null ? 4 : 0),
                                    child: Linkify(
                                      onOpen: (link) async {
                                        final Uri url = Uri.parse(link.url);
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                      },
                                      text: text,
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                      linkStyle: const TextStyle(color: AppTheme.primaryBlue, decoration: TextDecoration.underline),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
            ),
          );
      },
    );
  }
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardDark,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: const TextStyle(color: AppTheme.textGray),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onSubmitted: (val) => _sendMessage(text: val),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(text: _msgController.text),
            ),
          )
        ],
      ),
    );
  }
}

