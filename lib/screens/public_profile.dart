import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
          backgroundColor: Theme.of(context).cardColor,
          title: Text("Report User", style: TextStyle(color: Colors.redAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Why are you reporting this user?", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              SizedBox(height: 10),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText: "Enter reason...",
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User reported successfully. Our team will review this.")));
                  }
                }
              },
              child: Text("Submit Report"),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User has been blocked.")));
      Navigator.pop(context); // Go back
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Student Profile", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          PopupMenuButton<String>(
            color: Theme.of(context).cardColor,
            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
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
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("User not found.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.onSurface),
                ),
                SizedBox(height: 16),
                Text(data['fullName'] ?? "Student", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(data['bio'] ?? "No bio available.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                ),
                SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                      onPressed: () async {
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                        if (currentUserId == null) return;
                        final currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'Someone';

                        try {
                          // 1. Send Connection Request via RTDB
                          await FirebaseDatabase.instance.ref("connections/$userId/requests/$currentUserId").set(true);

                          // 2. Send Notification via Firestore
                          await FirebaseFirestore.instance.collection('notifications').add({
                            'userId': userId,
                            'type': 'connection',
                            'title': 'New Connection Request',
                            'body': '$currentUserName wants to connect with you.',
                            'createdAt': FieldValue.serverTimestamp(),
                            'read': false,
                            'senderId': currentUserId,
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Connection request sent!"), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to send request."), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.person_add),
                      label: Text("Connect"),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).cardColor),
                      onPressed: () {
                        // Send Message Logic
                      },
                      icon: Icon(Icons.message),
                      label: Text("Message"),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Skills Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassBoxDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Skills", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      SizedBox(height: 16),
                      StreamBuilder(
                        stream: FirebaseDatabase.instance.ref("users/$userId/skills").onValue,
                        builder: (context, AsyncSnapshot<DatabaseEvent> skillSnapshot) {
                          if (skillSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!skillSnapshot.hasData || skillSnapshot.data!.snapshot.value == null) {
                            return Text("No skills added yet.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant));
                          }
                          
                          final skillsData = skillSnapshot.data!.snapshot.value;
                          List<Map<dynamic, dynamic>> skillsList = [];
                          if (skillsData is List) {
                            skillsList = skillsData.where((e) => e != null).map((e) {
                              if (e is Map) {
                                return Map<dynamic, dynamic>.from(e);
                              }
                              return {'name': e.toString(), 'percentage': 50};
                            }).toList();
                          }
                          
                          if (skillsList.isEmpty) {
                            return Text("No skills added yet.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant));
                          }
                          
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skillsList.map((skill) {
                              return Chip(
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                label: Text(skill['name'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                side: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.5)),
                              );
                            }).toList(),
                          );
                        },
                      ),
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
