import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("DEMO PREVIEW (No real chats found)", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppTheme.primaryPurple, child: Icon(Icons.person, color: Colors.white)),
                  title: const Text("Sarah Johnson", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Hey! Can you help me with Flutter?", style: TextStyle(color: AppTheme.textGray)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textGray),
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(chatId: "demo1", otherUserId: "Sarah")));
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppTheme.primaryBlue, child: Icon(Icons.person, color: Colors.white)),
                  title: const Text("Alex Smith", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("I just completed the React course!", style: TextStyle(color: AppTheme.textGray)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textGray),
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(chatId: "demo2", otherUserId: "Alex")));
                  },
                ),
              ],
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              List participants = data['participants'] ?? [];
              String otherUserId = participants.firstWhere((id) => id != user?.uid, orElse: () => "Unknown");

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryPurple,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text("User: ${otherUserId.substring(0, 5)}...", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(data['lastMessage'] ?? "Tap to chat", style: const TextStyle(color: AppTheme.textGray)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textGray),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(chatId: docs[index].id, otherUserId: otherUserId)));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.message, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectionsPage()));
        },
      ),
    );
  }
}
