import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_student_platform/theme.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Stream<int> _getCollectionCount(String collectionPath) {
    return FirebaseFirestore.instance.collection(collectionPath).snapshots().map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 30),
            const Text("Platform Stats", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 30),
            const Text("Recent Activity", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String name = "Student";
        String profileUrl = "";
        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['fullName'] ?? data['username'] ?? "Student";
          profileUrl = data['profilePicture'] ?? "";
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: AppTheme.primaryPurple,
              backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
              child: profileUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome back,", style: TextStyle(color: AppTheme.textGray, fontSize: 16)),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard("Total Users", Icons.people, 'users'),
        _buildStatCard("Active Now", Icons.online_prediction, 'users'), // Simulating active
        _buildStatCard("Total Skills", Icons.star, 'skills'),
        _buildStatCard("Connections", Icons.handshake, 'connections'),
      ],
    );
  }

  Widget _buildStatCard(String title, IconData icon, String collection) {
    return Container(
      decoration: AppTheme.glassBoxDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 32),
          const SizedBox(height: 12),
          StreamBuilder<int>(
            stream: _getCollectionCount(collection),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple));
              }
              if (snapshot.hasError) {
                return const Text("Error", style: TextStyle(color: Colors.red));
              }
              int count = snapshot.data ?? 0;
              if (title == "Active Now") count = (count * 0.7).round(); // Fake active users for demo
              return Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppTheme.textGray, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassBoxDecoration,
      child: const Center(
        child: Text("No recent activity.", style: TextStyle(color: AppTheme.textGray)),
      ),
    );
  }
}
