import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_student_platform/src/file_io.dart';

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

  void _sendMessage({String? text, String? imageUrl, String? videoUrl, String? fileUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null && videoUrl == null && fileUrl == null) return;

    final msgText = text?.trim() ?? "";
    _msgController.clear();

    String displayLastMsg = msgText;
    if (imageUrl != null) displayLastMsg = '📷 Photo';
    if (videoUrl != null) displayLastMsg = '🎥 Video';
    if (fileUrl != null && displayLastMsg.isEmpty) displayLastMsg = '📎 Attachment';

    try {
      // Create/Update the chat document FIRST so it exists for security rules
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'lastMessage': displayLastMsg,
        'lastUpdated': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayUnion([user?.uid, widget.otherUserId]),
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
        'lastMessageSenderId': user?.uid,
      }, SetOptions(merge: true));

      // THEN add the message
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add({
        'senderId': user?.uid,
        'text': msgText.isNotEmpty ? msgText : null,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'fileUrl': fileUrl,
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
        'body': displayLastMsg.length > 30 ? '${displayLastMsg.substring(0, 30)}...' : displayLastMsg,
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

  Future<String> _uploadMediaBytes(Uint8List bytes, String path, String mimeType) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: mimeType));
      final snapshot = await uploadTask.timeout(const Duration(seconds: 8));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Storage upload timeout/CORS error ($e), using base64 fallback");
      if (bytes.length > 700000) {
        throw Exception("File size (${(bytes.length / 1024).round()} KB) exceeds limit for direct chat messaging. Please choose a smaller photo/video.");
      }
      return "data:$mimeType;base64,${base64Encode(bytes)}";
    }
  }

  void _showMediaPreviewAndSend({
    required Uint8List bytes,
    required String mimeType,
    required bool isVideo,
    required String storagePathPrefix,
  }) {
    final captionController = TextEditingController();
    bool isDialogUploading = false;

    showDialog(
      context: context,
      barrierDismissible: !isDialogUploading,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: SafeArea(
                child: Column(
                  children: [
                    AppBar(
                      backgroundColor: Colors.black,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: isDialogUploading ? null : () => Navigator.pop(dialogCtx),
                      ),
                      title: Text(
                        isVideo ? 'Preview Video' : 'Preview Photo',
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: isVideo
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: AppTheme.primaryPurple,
                                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 44),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Video Selected',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              )
                            : Container(
                                margin: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    bytes,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.black87,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: captionController,
                              enabled: !isDialogUploading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Add a caption...",
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          isDialogUploading
                              ? const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CircularProgressIndicator(color: AppTheme.primaryPurple),
                                )
                              : CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF25D366),
                                  child: IconButton(
                                    icon: const Icon(Icons.send, color: Colors.white, size: 22),
                                    onPressed: () async {
                                      setDialogState(() => isDialogUploading = true);
                                      try {
                                        final path = '$storagePathPrefix/${DateTime.now().millisecondsSinceEpoch}';
                                        final mediaUrl = await _uploadMediaBytes(bytes, path, mimeType);
                                        final caption = captionController.text.trim();
                                        if (isVideo) {
                                          _sendMessage(videoUrl: mediaUrl, text: caption.isNotEmpty ? caption : null);
                                        } else {
                                          _sendMessage(imageUrl: mediaUrl, text: caption.isNotEmpty ? caption : null);
                                        }
                                        if (mounted) Navigator.pop(dialogCtx);
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Send failed: ${e.toString().replaceAll('Exception: ', '')}')),
                                          );
                                        }
                                      } finally {
                                        if (mounted) setDialogState(() => isDialogUploading = false);
                                      }
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showWhatsAppAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWhatsAppAttachmentItem(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: const Color(0xFFE91E63),
                    onTap: () async {
                      Navigator.pop(bottomSheetCtx);
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 60,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        _showMediaPreviewAndSend(
                          bytes: bytes,
                          mimeType: 'image/jpeg',
                          isVideo: false,
                          storagePathPrefix: 'chat_images/${widget.chatId}',
                        );
                      }
                    },
                  ),
                  _buildWhatsAppAttachmentItem(
                    icon: Icons.photo_library,
                    label: 'Photos',
                    color: const Color(0xFFAC44CF),
                    onTap: () async {
                      Navigator.pop(bottomSheetCtx);
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 60,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        _showMediaPreviewAndSend(
                          bytes: bytes,
                          mimeType: 'image/jpeg',
                          isVideo: false,
                          storagePathPrefix: 'chat_images/${widget.chatId}',
                        );
                      }
                    },
                  ),
                  _buildWhatsAppAttachmentItem(
                    icon: Icons.videocam,
                    label: 'Video',
                    color: const Color(0xFFE542A3),
                    onTap: () async {
                      Navigator.pop(bottomSheetCtx);
                      final picker = ImagePicker();
                      final video = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
                      if (video != null) {
                        final bytes = await video.readAsBytes();
                        _showMediaPreviewAndSend(
                          bytes: bytes,
                          mimeType: 'video/mp4',
                          isVideo: true,
                          storagePathPrefix: 'chat_videos/${widget.chatId}',
                        );
                      }
                    },
                  ),
                  _buildWhatsAppAttachmentItem(
                    icon: Icons.insert_drive_file,
                    label: 'Document',
                    color: const Color(0xFF007AFF),
                    onTap: () async {
                      Navigator.pop(bottomSheetCtx);
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.isNotEmpty) {
                        final file = result.files.first;
                        if (file.bytes != null) {
                          setState(() => _isUploading = true);
                          try {
                            final path = 'chat_files/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
                            final fileUrl = await _uploadMediaBytes(file.bytes!, path, 'application/octet-stream');
                            _sendMessage(fileUrl: fileUrl, text: file.name);
                          } finally {
                            if (mounted) setState(() => _isUploading = false);
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWhatsAppAttachmentItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String? _tryDecodeDocumentText(String fileUrl) {
    try {
      if (fileUrl.startsWith('data:')) {
        final commaIndex = fileUrl.indexOf(',');
        if (commaIndex != -1) {
          final header = fileUrl.substring(0, commaIndex);
          final content = fileUrl.substring(commaIndex + 1);
          if (header.contains('base64')) {
            return utf8.decode(base64Decode(content));
          } else {
            return Uri.decodeComponent(content);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  void _confirmAndDeleteMessage(BuildContext dialogCtx, String messageId, String itemType) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Delete $itemType', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to delete this $itemType message?', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(confirmCtx);
              Navigator.pop(dialogCtx);
              await _deleteMessage(messageId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$itemType message deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showDocumentViewer(BuildContext context, String fileUrl, String fileName, {String? messageId, bool isMe = false}) {
    final String? decodedText = _tryDecodeDocumentText(fileUrl);

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF121212),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: const Color(0xFF1E1E1E),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Color(0xFF007AFF), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    tooltip: 'Download File',
                    onPressed: () {
                      downloadOrOpenFile(fileUrl, fileName);
                    },
                  ),
                  if (isMe && messageId != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Delete Document',
                      onPressed: () => _confirmAndDeleteMessage(dialogCtx, messageId, 'Document'),
                    ),
                ],
              ),
              Expanded(
                child: decodedText != null
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            decodedText,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontFamily: 'monospace',
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.insert_drive_file, color: Color(0xFF007AFF), size: 64),
                            const SizedBox(height: 16),
                            Text(
                              fileName,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Document Ready',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007AFF),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              icon: const Icon(Icons.download, color: Colors.white),
                              label: const Text('Download File', style: TextStyle(color: Colors.white, fontSize: 15)),
                              onPressed: () {
                                downloadOrOpenFile(fileUrl, fileName);
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenVideo(BuildContext context, String videoUrl, {String? messageId, bool isMe = false}) {
    final String viewType = 'video-view-${DateTime.now().millisecondsSinceEpoch}';
    registerVideoPlayerFactory(viewType, videoUrl);

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
                title: const Text('Video Message', style: TextStyle(color: Colors.white, fontSize: 18)),
                actions: [
                  if (isMe && messageId != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Delete Video',
                      onPressed: () => _confirmAndDeleteMessage(dialogCtx, messageId, 'Video'),
                    ),
                ],
              ),
              Expanded(
                child: Center(
                  child: HtmlElementView(viewType: viewType),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl, {String? messageId, bool isMe = false}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              if (isMe && messageId != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
                    tooltip: 'Delete Photo',
                    onPressed: () => _confirmAndDeleteMessage(ctx, messageId, 'Photo'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
                      final String? videoUrl = data['videoUrl'];
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
                                  GestureDetector(
                                    onTap: () => _showFullScreenImage(context, imageUrl, messageId: docs[index].id, isMe: isMe),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        width: 220,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return SizedBox(width: 220, height: 200, child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface)));
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 220,
                                            height: 180,
                                            color: Colors.grey[850],
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.image, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 40),
                                                  const SizedBox(height: 8),
                                                  Text('Tap to view photo', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                if (videoUrl != null)
                                   Padding(
                                     padding: const EdgeInsets.symmetric(vertical: 4.0),
                                     child: InkWell(
                                       onTap: () => _showFullScreenVideo(context, videoUrl, messageId: docs[index].id, isMe: isMe),
                                       child: Container(
                                         width: 220,
                                         padding: const EdgeInsets.all(12),
                                         decoration: BoxDecoration(
                                           color: Colors.black38,
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
                                                   Text(
                                                     'Video Message',
                                                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                   ),
                                                   Text(
                                                     'Tap to play in app',
                                                     style: TextStyle(color: Colors.white70, fontSize: 11),
                                                   ),
                                                 ],
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                   ),
                                 if (fileUrl != null)
                                   Padding(
                                     padding: const EdgeInsets.symmetric(vertical: 4.0),
                                     child: InkWell(
                                       onTap: () => _showDocumentViewer(context, fileUrl, text ?? 'Document', messageId: docs[index].id, isMe: isMe),
                                       child: Container(
                                         width: 220,
                                         padding: const EdgeInsets.all(12),
                                         decoration: BoxDecoration(
                                           color: Colors.black38,
                                           borderRadius: BorderRadius.circular(12),
                                         ),
                                         child: Row(
                                           children: [
                                             CircleAvatar(
                                               radius: 18,
                                               backgroundColor: const Color(0xFF007AFF),
                                               child: const Icon(Icons.insert_drive_file, color: Colors.white, size: 20),
                                             ),
                                             const SizedBox(width: 10),
                                             Expanded(
                                               child: Column(
                                                 crossAxisAlignment: CrossAxisAlignment.start,
                                                 children: [
                                                   Text(
                                                     text ?? 'Document',
                                                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                     maxLines: 1,
                                                     overflow: TextOverflow.ellipsis,
                                                   ),
                                                   const Text(
                                                     'Tap to view document',
                                                     style: TextStyle(color: Colors.white70, fontSize: 11),
                                                   ),
                                                 ],
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                   ),
                                if (text != null && text.isNotEmpty && fileUrl == null)
                                  Padding(
                                    padding: EdgeInsets.only(top: (imageUrl != null || videoUrl != null) ? 8 : 0, left: imageUrl != null ? 8 : 0, right: imageUrl != null ? 8 : 0, bottom: imageUrl != null ? 4 : 0),
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
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref("connections/${user!.uid}/accepted/${widget.otherUserId}").onValue,
      builder: (context, snapshot) {
        bool isConnected = false;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          isConnected = true;
        }

        if (!isConnected && snapshot.connectionState != ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Theme.of(context).cardColor,
            child: Text(
              "You must be connected to send messages.",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    icon: Icon(Icons.attach_file, color: AppTheme.primaryPurple, size: 24),
                    tooltip: 'Attach Media & Files',
                    onPressed: _isUploading ? null : _showWhatsAppAttachmentSheet,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      ),
                      onSubmitted: (val) => _sendMessage(text: val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: IconButton(
                      icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => _sendMessage(text: _msgController.text),
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

