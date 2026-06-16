import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_student_platform/theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No notifications right now.", style: TextStyle(color: AppTheme.textGray)));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              IconData icon = Icons.notifications;
              Color iconColor = Colors.white;

              if (data['type'] == 'connection') {
                icon = Icons.person_add;
                iconColor = Colors.blue;
              } else if (data['type'] == 'message') {
                icon = Icons.message;
                iconColor = Colors.green;
              } else if (data['type'] == 'group') {
                icon = Icons.group;
                iconColor = Colors.orange;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: AppTheme.glassBoxDecoration,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.2),
                    child: Icon(icon, color: iconColor),
                  ),
                  title: Text(data['title'] ?? 'Notification', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(data['body'] ?? '', style: const TextStyle(color: AppTheme.textGray)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
