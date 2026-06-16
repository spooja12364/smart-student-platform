import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_student_platform/theme.dart';

class MySkillsPage extends StatefulWidget {
  const MySkillsPage({super.key});

  @override
  State<MySkillsPage> createState() => _MySkillsPageState();
}

class _MySkillsPageState extends State<MySkillsPage> {
  final user = FirebaseAuth.instance.currentUser;

  void _showAddSkillModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSkillForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("My Skills", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: _showAddSkillModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('skills')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("You haven't added any skills yet.\nTap + to add one.", 
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGray, fontSize: 16)),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildSkillCard(data, docs[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> data, String docId) {
    final double proficiency = (data['proficiency'] ?? 0).toDouble();
    final String experienceText = data['experience']?.toString() ?? ((data['experienceYears'] != null && data['experienceYears'] != 0) ? "${data['experienceYears']} Years Exp" : "Not specified");
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassBoxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['skillName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  FirebaseFirestore.instance.collection('skills').doc(docId).delete();
                },
              )
            ],
          ),
          Text(data['category'] ?? '', style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(data['description'] ?? '', style: const TextStyle(color: AppTheme.textGray)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Proficiency", style: TextStyle(color: Colors.white)),
              Text("${proficiency.toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: proficiency / 100,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.history, color: AppTheme.textGray, size: 16),
              const SizedBox(width: 4),
              Text(experienceText, style: const TextStyle(color: AppTheme.textGray)),
              const Spacer(),
              if (data['teaching'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: const Text("Can Teach", style: TextStyle(color: Colors.green, fontSize: 12)),
                ),
              const SizedBox(width: 8),
              if (data['learning'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: const Text("Learning", style: TextStyle(color: Colors.orange, fontSize: 12)),
                )
            ],
          )
        ],
      ),
    );
  }
}

class AddSkillForm extends StatefulWidget {
  const AddSkillForm({super.key});
  @override
  State<AddSkillForm> createState() => _AddSkillFormState();
}

class _AddSkillFormState extends State<AddSkillForm> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  final _expController = TextEditingController();
  double _proficiency = 50;
  bool _teaching = false;
  bool _learning = false;

  void _saveSkill() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to save a skill.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Skill Name is required.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('skills').add({
        'userId': user.uid,
        'skillName': _nameController.text,
        'category': _categoryController.text,
        'description': _descController.text,
        'proficiency': _proficiency,
        'experience': _expController.text.trim(),
        'experienceYears': int.tryParse(_expController.text) ?? 0,
        'teaching': _teaching,
        'learning': _learning,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add New Skill", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField("Skill Name", _nameController),
            const SizedBox(height: 12),
            _buildTextField("Category", _categoryController),
            const SizedBox(height: 12),
            _buildTextField("Description", _descController, maxLines: 3),
            const SizedBox(height: 12),
            _buildTextField("Experience", _expController),
            const SizedBox(height: 20),
            Text("Proficiency: ${_proficiency.toInt()}%", style: const TextStyle(color: Colors.white)),
            Slider(
              value: _proficiency,
              min: 0, max: 100, divisions: 20,
              activeColor: AppTheme.primaryBlue,
              onChanged: (val) => setState(() => _proficiency = val),
            ),
            CheckboxListTile(
              title: const Text("I can teach this", style: TextStyle(color: Colors.white)),
              value: _teaching,
              activeColor: AppTheme.primaryPurple,
              onChanged: (val) => setState(() => _teaching = val ?? false),
            ),
            CheckboxListTile(
              title: const Text("I want to learn this", style: TextStyle(color: Colors.white)),
              value: _learning,
              activeColor: AppTheme.primaryPurple,
              onChanged: (val) => setState(() => _learning = val ?? false),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveSkill,
                child: const Text("Save Skill", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textGray),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
