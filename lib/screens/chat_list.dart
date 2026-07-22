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
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text('Please login to view chats.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Chats", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('connections/${user!.uid}/accepted').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Text('No connections yet. Connect with people first.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            );
          }

          final acceptedMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final List<String> connectedUserIds = acceptedMap.keys.toList();

          if (connectedUserIds.isEmpty) {
            return Center(
              child: Text('No connections yet. Connect with people first.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryPurple,
                        child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      title: Text('Connected user', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                      subtitle: Text('Tap to open chat', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                      int unreadCount = 0;
                      if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                        final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
                        subtitle = chatData['lastMessage'] ?? 'Start chatting';
                        unreadCount = chatData['unreadCount_${user!.uid}'] ?? 0;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryPurple,
                          backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                          child: profileImage.isEmpty ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface) : null,
                        ),
                        title: Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ],
                        ),
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
        child: Icon(Icons.person_add, color: Theme.of(context).colorScheme.onSurface),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const Connections()));
        },
      ),
    );
  }
}
