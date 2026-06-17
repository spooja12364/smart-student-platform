import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:smart_student_platform/src/file_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupChatDetailPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatDetailPage({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupChatDetailPage> createState() => _GroupChatDetailPageState();
}

class _GroupChatDetailPageState extends State<GroupChatDetailPage> {
  final _msgController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isUploading = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentPlayingUrl;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPlayingUrl = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _sendMessage({String? text, String? imageUrl, String? audioUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null && audioUrl == null) return;

    final msgText = text?.trim() ?? "";
    _msgController.clear();

    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('messages').add({
      'senderId': user?.uid,
      'senderName': user?.email ?? 'Unknown', // Ideally fetched from DB
      'text': msgText.isNotEmpty ? msgText : null,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).set({
      'lastMessage': audioUrl != null ? '🎤 Voice Note' : imageUrl != null ? '📷 Photo' : msgText,
      'lastUpdated': FieldValue.serverTimestamp(),
      'participants': FieldValue.arrayUnion([user?.uid]),
    }, SetOptions(merge: true));
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final storageRef = FirebaseStorage.instance.ref().child('group_images/${widget.groupId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final Uint8List bytes = await image.readAsBytes();
      await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final String downloadUrl = await storageRef.getDownloadURL();
      _sendMessage(imageUrl: downloadUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final filePath = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (filePath != null && filePath.isNotEmpty) {
        await _uploadVoiceNote(filePath);
      }
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission is required.')));
      }
      return;
    }

    final outputPath = tempFilePath('voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a');
    setState(() => _isRecording = true);
    await _audioRecorder.start(const RecordConfig(), path: outputPath);
  }

  Future<void> _uploadVoiceNote(String path) async {
    setState(() => _isUploading = true);
    try {
      Uint8List bytes;
      if (kIsWeb) {
        final response = await http.get(Uri.parse(path));
        bytes = response.bodyBytes;
      } else {
        bytes = await readFileBytes(path);
      }

      final storageRef = FirebaseStorage.instance.ref().child('group_audio/${widget.groupId}/${DateTime.now().millisecondsSinceEpoch}.m4a');
      await storageRef.putData(bytes, SettableMetadata(contentType: 'audio/m4a'));
      final String audioUrl = await storageRef.getDownloadURL();
      _sendMessage(audioUrl: audioUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload voice note: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _playAudio(String url) async {
    if (_currentPlayingUrl == url && _isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    await _audioPlayer.play(UrlSource(url));
    setState(() {
      _isPlaying = true;
      _currentPlayingUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(widget.groupName, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == user?.uid;
                    String? imageUrl = data['imageUrl'];
                    String? text = data['text'];
                    String? audioUrl = data['audioUrl'];

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                            if (!isMe && data['senderName'] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(data['senderName'], style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
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
                                ),
                              ),
                            if (audioUrl != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _currentPlayingUrl == audioUrl && _isPlaying ? Icons.pause_circle : Icons.play_circle,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      onPressed: () => _playAudio(audioUrl),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text("Voice Note", style: TextStyle(color: Colors.white, fontSize: 15)),
                                  ],
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
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: AppTheme.primaryPurple, backgroundColor: AppTheme.cardDark),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardDark,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: AppTheme.primaryPurple),
            onPressed: _pickAndUploadImage,
          ),
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop_circle : Icons.mic,
              color: _isRecording ? Colors.redAccent : AppTheme.textGray,
            ),
            onPressed: _toggleRecording,
          ),
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
