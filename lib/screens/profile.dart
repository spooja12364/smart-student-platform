import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Map<dynamic, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() {
    if (currentUser == null) return;
    FirebaseDatabase.instance.ref("users/${currentUser!.uid}").onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        setState(() {
          _userData = event.snapshot.value as Map<dynamic, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Please login."));

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryBlue,
                  backgroundImage: _userData['profileImage'] != null && _userData['profileImage'].toString().isNotEmpty
                      ? NetworkImage(_userData['profileImage'])
                      : null,
                  child: _userData['profileImage'] == null || _userData['profileImage'].toString().isEmpty
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(_userData['name'] ?? 'Student', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                
                _buildInfoCard(),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(userData: _userData)));
                    },
                    child: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _logout,
                    child: const Text("Logout", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email, "Email", _userData['email'] ?? currentUser?.email ?? ''),
          const Divider(color: Colors.white10, height: 24),
          _buildInfoRow(Icons.info_outline, "Bio", _userData['bio'] ?? 'No bio provided.'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textGray, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textGray, fontSize: 12)),
            Text(value.isEmpty ? "Not provided" : value, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        )
      ],
    );
  }
}
