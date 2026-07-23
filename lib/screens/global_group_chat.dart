import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isUploading = false;

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

  Future<String> _uploadMediaBytes(Uint8List bytes, String path, String mimeType) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: mimeType));
      final snapshot = await uploadTask.timeout(const Duration(seconds: 6));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Global Storage upload timeout/CORS error ($e), using base64 fallback");
      return "data:$mimeType;base64,${base64Encode(bytes)}";
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null || currentUser == null) return;

    setState(() => _isUploading = true);
    try {
      final path = 'global_chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Uint8List bytes = await image.readAsBytes();
      final String downloadUrl = await _uploadMediaBytes(bytes, path, 'image/jpeg');

      final newMessageRef = _chatRef.push();
      newMessageRef.set({
        "messageId": newMessageRef.key,
        "uid": currentUser!.uid,
        "sender": _userName,
        "imageUrl": downloadUrl,
        "timestamp": ServerValue.timestamp,
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndUploadVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
    if (video == null || currentUser == null) return;

    setState(() => _isUploading = true);
    try {
      final path = 'global_chat_videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final Uint8List bytes = await video.readAsBytes();
      final String downloadUrl = await _uploadMediaBytes(bytes, path, 'video/mp4');

      final newMessageRef = _chatRef.push();
      newMessageRef.set({
        "messageId": newMessageRef.key,
        "uid": currentUser!.uid,
        "sender": _userName,
        "videoUrl": downloadUrl,
        "timestamp": ServerValue.timestamp,
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload video: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _playOrOpenVideo(String videoUrl) async {
    try {
      final Uri uri = Uri.parse(videoUrl);
      if (videoUrl.startsWith('data:') || kIsWeb) {
        await launchUrl(uri);
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      debugPrint("Error opening video: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open video: $e")),
        );
      }
    }
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
          color: Theme.of(context).cardColor,
          width: double.infinity,
          child: Text(
            "Global Collaboration Chat",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: _chatRef.orderByChild('timestamp').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
              }

              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return Center(child: Text("No messages yet. Start the conversation!", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
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
                  final String? imageUrl = msg['imageUrl'];
                  final String? videoUrl = msg['videoUrl'];
                  final String? textMsg = msg['message'];

                  final timestamp = msg['timestamp'];
                  final DateTime? time = timestamp is int ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
                  final String timeString = time != null ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : '';

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primaryPurple : Theme.of(context).cardColor,
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
                              style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          if (imageUrl != null) ...[
                            const SizedBox(height: 4),
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
                              ),
                            ),
                          ],
                          if (videoUrl != null) ...[
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _playOrOpenVideo(videoUrl),
                              child: Container(
                                width: 200,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppTheme.primaryPurple,
                                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Video Clip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text('Tap to play', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (textMsg != null && textMsg.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              textMsg,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
                            ),
                          ],
                          if (timeString.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              timeString,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.9), fontSize: 11),
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
        if (_isUploading)
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple)),
                const SizedBox(width: 8),
                Text('Uploading media...', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.photo_camera, color: AppTheme.primaryPurple, size: 22),
                tooltip: 'Send Photo',
                onPressed: _isUploading ? null : _pickAndUploadImage,
              ),
              IconButton(
                icon: Icon(Icons.videocam, color: AppTheme.primaryPurple, size: 22),
                tooltip: 'Send Video',
                onPressed: _isUploading ? null : _pickAndUploadVideo,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryPurple,
                child: IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onSurface),
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
