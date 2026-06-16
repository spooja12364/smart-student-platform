import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/public_profile.dart';

class AIMatching extends StatefulWidget {
  const AIMatching({super.key});

  @override
  State<AIMatching> createState() => _AIMatchingState();
}

class _AIMatchingState extends State<AIMatching> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("AI Skill Matches", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Find students who can teach what you want to learn.", style: TextStyle(color: AppTheme.textGray)),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // In a real app, you would query users based on complex AI matching. 
                  // For UI prototype, we just fetch all skills where teaching == true
                  stream: FirebaseFirestore.instance.collection('skills').where('teaching', isEqualTo: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                    
                    final docs = snapshot.data!.docs.where((doc) => (doc.data() as Map<String, dynamic>)['userId'] != user?.uid).toList();

                    if (docs.isEmpty) {
                      return const Center(child: Text("No matches found yet.", style: TextStyle(color: AppTheme.textGray)));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final skillData = docs[index].data() as Map<String, dynamic>;
                        return _buildMatchCard(skillData);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> skillData) {
    // Generate a random match percentage for demo purposes (usually calculated backend)
    int matchPercentage = 85 + (skillData.hashCode % 15);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(userId: skillData['userId'])));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassBoxDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primaryPurple,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Suggested Match", style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                    Text("User ID: ${skillData['userId'].toString().substring(0, 5)}...", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("$matchPercentage% Match", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text("They can teach: ${skillData['skillName']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Category: ${skillData['category']}", style: const TextStyle(color: AppTheme.textGray)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // Send connection request logic
                  },
                  icon: const Icon(Icons.handshake, color: Colors.white, size: 18),
                  label: const Text("Connect", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // Message logic
                  },
                  icon: const Icon(Icons.message, color: Colors.white, size: 18),
                  label: const Text("Message", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}
}
