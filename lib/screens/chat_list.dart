import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/chat_detail.dart';
import 'package:smart_student_platform/screens/connections.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(child: Text('Please login to view chats.', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("Chats", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('connections/${user!.uid}/accepted').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('No connections yet. Connect with people first.', style: TextStyle(color: AppTheme.textGray)),
            );
          }

          final acceptedMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final List<String> connectedUserIds = acceptedMap.keys.toList();

          if (connectedUserIds.isEmpty) {
            return const Center(
              child: Text('No connections yet. Connect with people first.', style: TextStyle(color: AppTheme.textGray)),
            );
          }

          return ListView.builder(
            itemCount: connectedUserIds.length,
            itemBuilder: (context, index) {
              final otherUserId = connectedUserIds[index];
              final List<String> uids = [user!.uid, otherUserId];
              uids.sort();
              final String chatId = uids.join('_');

              return FutureBuilder<DatabaseEvent>(
                future: FirebaseDatabase.instance.ref('users/$otherUserId').once(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data!.snapshot.value == null) {
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryPurple,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: const Text('Connected user', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Tap to open chat', style: TextStyle(color: AppTheme.textGray)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailPage(chatId: chatId, otherUserId: otherUserId),
                          ),
                        );
                      },
                    );
                  }

                  final otherUser = Map<String, dynamic>.from(userSnapshot.data!.snapshot.value as Map);
                  final name = (otherUser['fullName'] ?? otherUser['name'] ?? 'Student').toString();
                  final profileImage = (otherUser['profilePicture'] ?? otherUser['profileImage'] ?? '').toString();

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
                    builder: (context, chatSnapshot) {
                      String subtitle = 'Start chatting';
                      if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                        final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
                        subtitle = chatData['lastMessage'] ?? 'Start chatting';
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryPurple,
                          backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                          child: profileImage.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textGray)),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.textGray),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailPage(chatId: chatId, otherUserId: otherUserId, otherUserName: name),
                            ),
                          );
                        },
                      );
                    }
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const Connections()));
        },
      ),
    );
  }
}
