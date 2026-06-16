import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/create_group.dart';

class GroupChatListPage extends StatefulWidget {
  const GroupChatListPage({super.key});

  @override
  State<GroupChatListPage> createState() => _GroupChatListPageState();
}

class _GroupChatListPageState extends State<GroupChatListPage> {
  final List<Map<String, String>> _demoGroups = [
    {
      'name': 'Study Buddies',
      'description': 'Collaborate with peers across subjects and share study tips.',
    },
    {
      'name': 'Exam Prep Crew',
      'description': 'Discuss important exam topics and practice together.',
    },
    {
      'name': 'Project Partners',
      'description': 'Team up for coursework, assignments, and peer review.',
    },
  ];

  Future<void> _injectDemoGroups() async {
    for (final group in _demoGroups) {
      await FirebaseFirestore.instance.collection('groups').add({
        'name': group['name'],
        'description': group['description'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _createGroup() {
    // Show dialog to create group
    showDialog(
      context: context,
      builder: (context) {
        final _nameController = TextEditingController();
        final _descController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text("Create Group", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Group Name",
                  labelStyle: const TextStyle(color: AppTheme.textGray),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Description",
                  labelStyle: const TextStyle(color: AppTheme.textGray),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: AppTheme.textGray))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('groups').add({
                    'name': _nameController.text,
                    'description': _descController.text,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Create"),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("Study Groups", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("No groups available yet.", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text("Try the demo groups below or create a new study group.", style: TextStyle(color: AppTheme.textGray)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: _injectDemoGroups,
                      child: const Text("Inject Demo Groups", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._demoGroups.map((group) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: AppTheme.glassBoxDecoration,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.group, color: AppTheme.primaryBlue),
                        ),
                        title: Text(group['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(group['description']!, style: const TextStyle(color: AppTheme.textGray)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {},
                          child: const Text("Join", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.glassBoxDecoration,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.group, color: AppTheme.primaryBlue),
                  ),
                  title: Text(data['name'] ?? "Group", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(data['description'] ?? "No description", style: const TextStyle(color: AppTheme.textGray)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {},
                    child: const Text("Join", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateGroupScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
