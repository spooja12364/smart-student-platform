import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_student_platform/theme.dart';

class PublicProfilePage extends StatelessWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  void _reportUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text("Report User", style: TextStyle(color: Colors.redAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Why are you reporting this user?", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText: "Enter reason...",
                  hintStyle: const TextStyle(color: AppTheme.textGray),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: AppTheme.textGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final reporterId = FirebaseAuth.instance.currentUser?.uid;
                if (reporterId != null && reasonController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('reports').add({
                    'reporterId': reporterId,
                    'reportedUserId': userId,
                    'reason': reasonController.text,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User reported successfully. Our team will review this.")));
                  }
                }
              },
              child: const Text("Submit Report"),
            )
          ],
        );
      },
    );
  }

  void _blockUser(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Add to blocked users collection
    await FirebaseFirestore.instance.collection('blocks').add({
      'blockerId': currentUserId,
      'blockedUserId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User has been blocked.")));
      Navigator.pop(context); // Go back
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("Student Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            color: AppTheme.cardDark,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'report') {
                _reportUser(context);
              } else if (value == 'block') {
                _blockUser(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'report', child: Text("Report User", style: TextStyle(color: Colors.redAccent))),
              const PopupMenuItem(value: 'block', child: Text("Block User", style: TextStyle(color: Colors.redAccent))),
            ],
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found.", style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(data['fullName'] ?? "Student", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(data['collegeName'] ?? "University", style: const TextStyle(color: AppTheme.textGray)),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                      onPressed: () {
                        // Send Connection Logic
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text("Connect"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardDark),
                      onPressed: () {
                        // Send Message Logic
                      },
                      icon: const Icon(Icons.message),
                      label: const Text("Message"),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassBoxDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("About", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      const SizedBox(height: 8),
                      Text(data['bio'] ?? "No bio available.", style: const TextStyle(color: Colors.white)),
                      const Divider(color: Colors.white24, height: 30),
                      
                      const Text("City", style: TextStyle(color: AppTheme.textGray)),
                      Text(data['city'] ?? "Not specified", style: const TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 16),
                      
                      const Text("Department", style: TextStyle(color: AppTheme.textGray)),
                      Text(data['department'] ?? "Not specified", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
