import 'dart:convert';
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

  void _sendMessage({String? text, String? imageUrl, String? videoUrl, String? audioUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null && videoUrl == null && audioUrl == null) return;

    final msgText = text?.trim() ?? "";
    _msgController.clear();

    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('messages').add({
      'senderId': user?.uid,
      'senderName': user?.email ?? 'Unknown', // Ideally fetched from DB
      'text': msgText.isNotEmpty ? msgText : null,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).set({
      'lastMessage': videoUrl != null ? '🎥 Video' : audioUrl != null ? '🎤 Voice Note' : imageUrl != null ? '📷 Photo' : msgText,
      'lastUpdated': FieldValue.serverTimestamp(),
      'participants': FieldValue.arrayUnion([user?.uid]),
    }, SetOptions(merge: true));
  }

  Future<String> _uploadMediaBytes(Uint8List bytes, String path, String mimeType) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: mimeType));
      final snapshot = await uploadTask.timeout(const Duration(seconds: 6));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Group Storage upload timeout/CORS error ($e), using base64 fallback");
      return "data:$mimeType;base64,${base64Encode(bytes)}";
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final path = 'group_images/${widget.groupId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Uint8List bytes = await image.readAsBytes();
      final String downloadUrl = await _uploadMediaBytes(bytes, path, 'image/jpeg');
      _sendMessage(imageUrl: downloadUrl);
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
    
    if (video == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final path = 'group_videos/${widget.groupId}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final Uint8List bytes = await video.readAsBytes();
      final String downloadUrl = await _uploadMediaBytes(bytes, path, 'video/mp4');
      _sendMessage(videoUrl: downloadUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload video: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Microphone permission is required.')));
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.groupName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
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
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == user?.uid;
                    String? imageUrl = data['imageUrl'];
                    String? videoUrl = data['videoUrl'];
                    String? text = data['text'];
                    String? audioUrl = data['audioUrl'];

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                            if (!isMe && data['senderName'] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(data['senderName'], style: TextStyle(color: AppTheme.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold)),
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
                                    return SizedBox(width: 200, height: 200, child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface)));
                                  },
                                ),
                              ),
                            if (videoUrl != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: InkWell(
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
                                              Text(
                                                'Video Clip',
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              Text(
                                                'Tap to play',
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
                            if (audioUrl != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _currentPlayingUrl == audioUrl && _isPlaying ? Icons.pause_circle : Icons.play_circle,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        size: 32,
                                      ),
                                      onPressed: () => _playAudio(audioUrl),
                                    ),
                                    SizedBox(width: 8),
                                    Text("Voice Note", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
                                  ],
                                ),
                              ),
                            if (text != null && text.isNotEmpty)
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
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: AppTheme.primaryPurple, backgroundColor: Theme.of(context).cardColor),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image, color: AppTheme.primaryPurple),
            tooltip: 'Send Photo',
            onPressed: _isUploading ? null : _pickAndUploadImage,
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: AppTheme.primaryPurple),
            tooltip: 'Send Video',
            onPressed: _isUploading ? null : _pickAndUploadVideo,
          ),
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop_circle : Icons.mic,
              color: _isRecording ? Colors.redAccent : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: _toggleRecording,
          ),
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
