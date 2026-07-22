import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/search_discover.dart';

class DashboardHome extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const DashboardHome({super.key, this.onNavigate});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  String _currentAiTip = "Loading AI Insights...";
  bool _isLoadingAiTip = true;

  @override
  void initState() {
    super.initState();
    _fetchAiTip();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  Future<void> _fetchAiTip() async {
    try {
      final googleAI = FirebaseAI.googleAI(auth: FirebaseAuth.instance);
      final model = googleAI.generativeModel(model: 'gemini-3.1-flash-lite');
      
      final prompt = "Give a single, concise (under 120 characters) tip for a user named '${user?.displayName ?? 'Student'}' on how to improve their profile, connections, or study skills on an academic networking app.";
      
      final response = await model.generateContent([Content.text(prompt)]);
      
      if (mounted) {
        setState(() {
          _currentAiTip = response.text?.replaceAll('"', '').trim() ?? "AI Tip: Expand your connections today!";
          _isLoadingAiTip = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAiTip = "AI Tip: Adding more skills boosts your profile visibility.";
          _isLoadingAiTip = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Stream<int> _getStatCount(String type) {
    if (type == 'users') {
      return FirebaseFirestore.instance.collection('users').snapshots().map((snap) => snap.docs.length);
    } else if (type == 'skills') {
      if (user == null) return Stream.value(0);
      return FirebaseDatabase.instance.ref('users/${user!.uid}/skills').onValue.map((event) {
        if (event.snapshot.value != null && event.snapshot.value is List) {
          return (event.snapshot.value as List).where((e) => e != null).length;
        }
        return 0;
      });
    } else if (type == 'connections') {
      if (user == null) return Stream.value(0);
      return FirebaseDatabase.instance.ref('connections/${user!.uid}/accepted').onValue.map((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          return (event.snapshot.value as Map).length;
        }
        return 0;
      });
    }
    return Stream.value(0);
  }

  String _safeDisplayName(Map<String, dynamic>? data) {
    if (data == null) return 'Student';
    return (data['fullName'] ?? data['name'] ?? data['username'] ?? 'Student').toString();
  }

  String _safeProfileUrl(Map<String, dynamic>? data) {
    if (data == null) return '';
    return (data['profilePicture'] ?? data['profileImage'] ?? '').toString();
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
            SizedBox(height: 24),
            _buildAISuggestionCard(),
            SizedBox(height: 24),
            Text("Quick Actions", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.search,
                    label: "Discover",
                    color: AppTheme.primaryPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchDiscover()),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.person_add,
                    label: "Connect",
                    color: AppTheme.primaryBlue,
                    onTap: () {
                      widget.onNavigate?.call(2); // Go to Connections tab
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.star,
                    label: "Add Skill",
                    color: Colors.orangeAccent,
                    onTap: () {
                      widget.onNavigate?.call(1); // Go to Skills tab
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text("Platform Overview", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildStatsGrid(),
            SizedBox(height: 24),
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
          name = _safeDisplayName(data);
          profileUrl = _safeProfileUrl(data);
        }

        return Row(
          children: [

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back,", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
                  Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
        double aspectRatio = constraints.maxWidth > 600 ? 2.8 : 2.2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard("Total Users", Icons.people, 'users'),
            _buildStatCard("Active Now", Icons.online_prediction, 'users'), // Simulating active
            _buildStatCard("Total Skills", Icons.star, 'skills'),
            _buildStatCard("Connections", Icons.handshake, 'connections'),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, IconData icon, String collection) {
    return Container(
      decoration: AppTheme.glassBoxDecoration(context),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder<int>(
                  stream: _getStatCount(collection),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple));
                    }
                    if (snapshot.hasError) {
                      return Text("Error", style: TextStyle(color: Colors.red));
                    }
                    int count = snapshot.data ?? 0;
                    if (title == "Active Now") count = (count * 0.7).round(); // Fake active users for demo
                    return Text(
                      count.toString(),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAISuggestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.onSurface, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Smart Insights",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                _isLoadingAiTip
                    ? SizedBox(height: 14, width: 14, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface, strokeWidth: 2))
                    : Text(
                        _currentAiTip,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
