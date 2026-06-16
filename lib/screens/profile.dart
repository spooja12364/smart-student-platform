import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (!snapshot.data!.exists) return const Center(child: Text("Profile not found", style: TextStyle(color: Colors.white)));

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryPurple,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(data['fullName'] ?? "Student", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(data['email'] ?? "", style: const TextStyle(color: AppTheme.textGray)),
                const SizedBox(height: 24),
                
                _buildInfoCard("Personal Details", [
                  _infoRow("Username", data['username'] ?? "Not added"),
                  _infoRow("City", data['city'] ?? "Not added"),
                  _infoRow("Bio", data['bio'] ?? "No bio available"),
                ]),
                const SizedBox(height: 16),
                _buildInfoCard("Skills", [
                  if (data['skills'] != null && (data['skills'] as List).isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      children: (data['skills'] as List).map<Widget>((skill) {
                        return Chip(
                          label: Text(skill.toString(), style: const TextStyle(color: Colors.white)),
                          backgroundColor: AppTheme.primaryPurple,
                        );
                      }).toList(),
                    )
                  else
                    const Text("No skills added during registration.", style: TextStyle(color: AppTheme.textGray)),
                ]),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showEditProfileDialog(context, data),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showChangePasswordDialog(context),
                    icon: const Icon(Icons.lock_reset, color: Colors.white),
                    label: const Text("Change Password", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, Map<String, dynamic> data) {
    final fullNameController = TextEditingController(text: data['fullName'] ?? '');
    final cityController = TextEditingController(text: data['city'] ?? '');
    final bioController = TextEditingController(text: data['bio'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fullNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Full Name",
                      hintStyle: const TextStyle(color: AppTheme.textGray),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "City",
                      hintStyle: const TextStyle(color: AppTheme.textGray),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bioController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Short Bio",
                      hintStyle: const TextStyle(color: AppTheme.textGray),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isSaving ? null : () async {
                    final name = fullNameController.text.trim();
                    final city = cityController.text.trim();
                    final bio = bioController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your full name.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                      return;
                    }

                    setDialogState(() => isSaving = true);
                    try {
                      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                        'fullName': name,
                        'city': city,
                        'bio': bio,
                      });
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not update profile: $e", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                    }
                  },
                  child: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isUpdating = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Change Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Current Password",
                      hintStyle: const TextStyle(color: AppTheme.textGray),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "New Password (min 6 chars)",
                      hintStyle: const TextStyle(color: AppTheme.textGray),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isUpdating ? null : () async {
                    if (currentPasswordController.text.isEmpty || newPasswordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields correctly (New password min 6 chars).")));
                      return;
                    }

                    setDialogState(() => isUpdating = true);
                    try {
                      final cred = EmailAuthProvider.credential(email: user!.email!, password: currentPasswordController.text);
                      await user!.reauthenticateWithCredential(cred);
                      await user!.updatePassword(newPasswordController.text);

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                    } on FirebaseAuthException catch (e) {
                      setDialogState(() => isUpdating = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                    }
                  },
                  child: isUpdating 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Update", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassBoxDecoration,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppTheme.textGray))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
