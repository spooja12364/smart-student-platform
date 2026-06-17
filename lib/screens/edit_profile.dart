import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_student_platform/theme.dart';

class EditProfilePage extends StatefulWidget {
  final Map<dynamic, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _imageUrlController;
  Uint8List? _pickedImageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    _imageUrlController = TextEditingController(text: widget.userData['profileImage'] ?? '');
  }

  Future<String?> _uploadProfileImage() async {
    if (currentUser == null || _pickedImageBytes == null) return null;
    final storageRef = FirebaseStorage.instance.ref('profile_images/${currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await storageRef.putData(_pickedImageBytes!, SettableMetadata(contentType: 'image/jpeg'));
    return await storageRef.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    setState(() => _isSaving = true);

    try {
      String imageUrl = _imageUrlController.text.trim();
      if (_pickedImageBytes != null) {
        try {
          final uploadedUrl = await _uploadProfileImage().timeout(const Duration(seconds: 10));
          if (uploadedUrl != null) {
            imageUrl = uploadedUrl;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not upload image, but saving other changes. Error: $e')));
          }
        }
      }

      final updatedName = _nameController.text.trim();
      final updatedBio = _bioController.text.trim();
      final updatedImage = imageUrl;

      try {
        await FirebaseDatabase.instance.ref("users/${currentUser!.uid}").update({
          "name": updatedName,
          "fullName": updatedName,
          "bio": updatedBio,
          "profileImage": updatedImage,
          "profilePicture": updatedImage,
        }).timeout(const Duration(seconds: 5));
      } catch (_) {}

      try {
        await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
          'uid': currentUser!.uid,
          'name': updatedName,
          'fullName': updatedName,
          'email': currentUser!.email,
          'bio': updatedBio,
          'profileImage': updatedImage,
          'profilePicture': updatedImage,
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textGray),
          filled: true,
          fillColor: AppTheme.cardDark,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryPurple)),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    if (kIsWeb) {
      _pickedImageBytes = await picked.readAsBytes();
    } else {
      _pickedImageBytes = await picked.readAsBytes();
    }

    if (mounted) setState(() {
      _imageUrlController.text = picked.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pickedImageBytes != null ? "Selected image ready to upload" : (_imageUrlController.text.isNotEmpty ? "Using existing image URL" : "Choose profile photo"),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textGray),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildField("Full Name", _nameController),
            _buildField("Short Bio", _bioController, maxLines: 4),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
