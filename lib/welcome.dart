import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_student_platform/theme.dart';
import 'register.dart';
import 'login.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Stream<int> _getCollectionCount(String collectionPath) {
    return FirebaseFirestore.instance.collection(collectionPath).snapshots().map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    // For responsive layout
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.darkBg, AppTheme.cardDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.school, size: 80, color: AppTheme.primaryBlue),
                  const SizedBox(height: 24),
                  const Text(
                    "Smart Student Platform",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "The Ultimate AI-Powered Collaboration Hub for Students.\nLearn • Connect • Grow",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color: AppTheme.textGray),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                        child: const Text("Get Started", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                      const SizedBox(width: 20),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text("Log In", style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Stats Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: isDesktop 
                  ? Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _buildStatsWidgets())
                  : Column(children: _buildStatsWidgets().map((w) => Padding(padding: const EdgeInsets.only(bottom: 20), child: w)).toList()),
            ),

            // Features Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              color: AppTheme.cardDark,
              child: Column(
                children: [
                  const Text("Platform Features", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildFeatureCard(Icons.auto_awesome, "AI Skill Matching", "Find peers based on what you want to learn and teach."),
                      _buildFeatureCard(Icons.chat, "Real-time Messaging", "Connect instantly with your matches and groups."),
                      _buildFeatureCard(Icons.security, "Secure Environment", "Verified students with strict profile moderation."),
                    ],
                  )
                ],
              ),
            ),
            
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              color: AppTheme.darkBg,
              child: const Text("© 2026 Smart Student Platform. Ready for Public Launch.", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: AppTheme.textGray)),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatsWidgets() {
    return [
      _buildStatItem("Total Users", 'users', Icons.people),
      _buildStatItem("Skills Shared", 'skills', Icons.star),
      _buildStatItem("Connections Made", 'connections', Icons.handshake),
      _buildStatItem("Active Groups", 'groups', Icons.groups),
    ];
  }

  Widget _buildStatItem(String label, String collection, IconData icon) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassBoxDecoration,
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.primaryPurple),
          const SizedBox(height: 16),
          StreamBuilder<int>(
            stream: _getCollectionCount(collection),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator(color: AppTheme.primaryBlue);
              return Text(
                "${snapshot.data}",
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppTheme.textGray, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.darkBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: AppTheme.primaryBlue),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(color: AppTheme.textGray, height: 1.5)),
        ],
      ),
    );
  }
}