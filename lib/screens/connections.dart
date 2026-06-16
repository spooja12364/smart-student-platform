import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/chat_detail.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("Connections", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryPurple,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textGray,
          tabs: const [
            Tab(text: "Connected"),
            Tab(text: "Pending"),
            Tab(text: "Sent"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectionsList("accepted"),
          _buildConnectionsList("pending_received"),
          _buildConnectionsList("pending_sent"),
        ],
      ),
    );
  }

  Widget _buildConnectionsList(String type) {
    // In a real schema, you'd query where status = 'accepted' or 'pending' and from/to matches currentUser
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('connections').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
        
        // Manual filtering for UI demo purpose
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (type == "accepted") {
            return data['status'] == 'accepted' && (data['user1'] == user?.uid || data['user2'] == user?.uid);
          } else if (type == "pending_received") {
            return data['status'] == 'pending' && data['to'] == user?.uid;
          } else {
            return data['status'] == 'pending' && data['from'] == user?.uid;
          }
        }).toList();

        if (docs.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text("DEMO PREVIEW (No real connections found)", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
              _buildConnectionCard({'from': 'demo1', 'to': 'demo2', 'status': type == 'pending_received' ? 'pending' : 'accepted'}, type, 'demo_doc_1', isDemo: true, demoName: 'Sarah Johnson'),
              _buildConnectionCard({'from': 'demo3', 'to': 'demo4', 'status': type == 'pending_sent' ? 'pending' : 'accepted'}, type, 'demo_doc_2', isDemo: true, demoName: 'Alex Smith'),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildConnectionCard(data, type, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildConnectionCard(Map<String, dynamic> data, String type, String docId, {bool isDemo = false, String? demoName}) {
    String displayUserId = isDemo ? demoName! : ((data['from'] == user?.uid) ? (data['to'] ?? "Unknown") : (data['from'] ?? "Unknown"));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassBoxDecoration,
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isDemo ? demoName! : "User ID: ${displayUserId.length > 5 ? displayUserId.substring(0, 5) : displayUserId}...", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Text("Student", style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
              ],
            ),
          ),
          if (type == "pending_received") ...[
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () {
                FirebaseFirestore.instance.collection('connections').doc(docId).update({
                  'status': 'accepted',
                  'user1': data['from'],
                  'user2': data['to'],
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.redAccent),
              onPressed: () {
                FirebaseFirestore.instance.collection('connections').doc(docId).delete();
              },
            )
          ] else if (type == "accepted") ...[
            IconButton(
              icon: const Icon(Icons.message, color: AppTheme.primaryPurple),
              onPressed: () async {
                if (user == null) return;
                
                // Sort IDs to create a unique chat document ID regardless of who started it
                List<String> participants = [user!.uid, displayUserId]..sort();
                String chatId = "${participants[0]}_${participants[1]}";
                
                final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
                final docSnapshot = await chatDoc.get();
                
                // If chat doesn't exist, create it
                if (!docSnapshot.exists) {
                  await chatDoc.set({
                    'participants': participants,
                    'lastMessage': '',
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });
                }
                
                if (context.mounted) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => ChatDetailPage(chatId: chatId, otherUserId: displayUserId)
                    )
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_remove, color: Colors.redAccent),
              onPressed: () {
                FirebaseFirestore.instance.collection('connections').doc(docId).delete();
              },
            )
          ] else ...[
            const Text("Pending", style: TextStyle(color: Colors.orange)),
          ]
        ],
      ),
    );
  }
}
