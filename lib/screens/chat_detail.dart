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
  void initState() {
    super.initState();
    // Reset unread count when opening the chat
    if (user != null) {
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'unreadCount_${user!.uid}': 0,
      }, SetOptions(merge: true));
    }
  }

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
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
        'lastMessageSenderId': user?.uid,
      }, SetOptions(merge: true));

      // THEN add the message
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add({
        'senderId': user?.uid,
        'text': msgText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // FINALLY add a notification for the other user
      String senderName = 'Someone';
      if (user != null) {
        if (user!.displayName != null && user!.displayName!.isNotEmpty) {
          senderName = user!.displayName!;
        } else {
          try {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
            if (userDoc.exists && userDoc.data() != null) {
              senderName = userDoc.data()!['fullName'] ?? userDoc.data()!['name'] ?? 'Someone';
            }
          } catch (_) {}
        }
      }
      
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': widget.otherUserId,
        'type': 'message',
        'title': 'New message from $senderName',
        'body': msgText.length > 30 ? '${msgText.substring(0, 30)}...' : msgText,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'senderId': user?.uid,
      });
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text('Send Failed', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            content: Text('Database Error: $e\n\nPlease check your Firestore Rules.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: TextStyle(color: AppTheme.primaryPurple))),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Chat', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        ),
        body: Center(
          child: Text('Please sign in to use chat.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Chat with $otherUserName', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            backgroundColor: Theme.of(context).cardColor,
            elevation: 0,
            iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
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
                    return Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(child: Text('No messages yet. Start the conversation.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
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
                                    backgroundColor: Theme.of(context).cardColor,
                                    builder: (context) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          if (text != null && text.isNotEmpty)
                                            ListTile(
                                              leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
                                              title: Text('Edit Message', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _msgController.text = text;
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    final editController = TextEditingController(text: text);
                                                    return AlertDialog(
                                                      backgroundColor: Theme.of(context).cardColor,
                                                      title: Text('Edit Message', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                                      content: TextField(
                                                        controller: editController,
                                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                                        decoration: const InputDecoration(
                                                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryPurple)),
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                                                          child: Text('Save', style: TextStyle(color: AppTheme.primaryPurple)),
                                                        ),
                                                      ],
                                                    );
                                                  }
                                                );
                                              },
                                            ),
                                          ListTile(
                                            leading: Icon(Icons.delete, color: Colors.redAccent),
                                            title: Text('Delete Message', style: TextStyle(color: Colors.redAccent)),
                                            onTap: () async {
                                              Navigator.pop(context);
                                              await _deleteMessage(docs[index].id);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message deleted')));
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
                              color: isMe ? AppTheme.primaryBlue : Theme.of(context).cardColor,
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
                                        return SizedBox(width: 200, height: 200, child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface)));
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 200,
                                          height: 200,
                                          color: Colors.grey[800],
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onSurface, size: 40),
                                                SizedBox(height: 8),
                                                Text('Could not load image\n(CORS/Permissions)', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
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
                                          Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurface, size: 24),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              text ?? 'Download file',
                                              style: TextStyle(color: AppTheme.primaryBlue, fontSize: 15, decoration: TextDecoration.underline),
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
                                      style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, fontSize: 15),
                                      linkStyle: TextStyle(color: AppTheme.primaryBlue, decoration: TextDecoration.underline),
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
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onSubmitted: (val) => _sendMessage(text: val),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            child: IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => _sendMessage(text: _msgController.text),
            ),
          )
        ],
      ),
    );
  }
}

