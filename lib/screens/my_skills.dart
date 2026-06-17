import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_student_platform/theme.dart';

class MySkills extends StatefulWidget {
  const MySkills({super.key});

  @override
  State<MySkills> createState() => _MySkillsState();
}

class _MySkillsState extends State<MySkills> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late DatabaseReference _userRef;
  List<Map<dynamic, dynamic>> _skills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _userRef = FirebaseDatabase.instance.ref("users/${currentUser!.uid}/skills");
      _fetchSkills();
    }
  }

  void _fetchSkills() {
    _userRef.onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        final data = event.snapshot.value;
        if (data is List) {
          setState(() {
            _skills = data.map((e) {
              if (e is Map) {
                return Map<dynamic, dynamic>.from(e);
              } else {
                return {
                  'name': e.toString(),
                  'percentage': 50,
                  'description': ''
                };
              }
            }).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _skills = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _skills = [];
          _isLoading = false;
        });
      }
    });
  }

  void _showAddEditSkillDialog([Map<dynamic, dynamic>? existingSkill, int? index]) {
    final TextEditingController nameController = TextEditingController(text: existingSkill?['name'] ?? '');
    final TextEditingController descController = TextEditingController(text: existingSkill?['description'] ?? '');
    String mode = existingSkill?['mode']?.toString() ?? 'Teach';
    double percentage = (existingSkill?['percentage'] ?? 50.0).toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardDark,
              title: Text(existingSkill == null ? "Add Skill" : "Edit Skill", style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Skill Name",
                        labelStyle: const TextStyle(color: AppTheme.textGray),
                        hintText: "e.g. Flutter, Firebase, AI",
                        hintStyle: const TextStyle(color: AppTheme.textGray),
                        filled: true,
                        fillColor: AppTheme.darkBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Description",
                        labelStyle: const TextStyle(color: AppTheme.textGray),
                        hintText: "Briefly describe your experience",
                        hintStyle: const TextStyle(color: AppTheme.textGray),
                        filled: true,
                        fillColor: AppTheme.darkBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Teach'),
                          selected: mode == 'Teach',
                          onSelected: (_) => setDialogState(() => mode = 'Teach'),
                          selectedColor: AppTheme.primaryPurple,
                          backgroundColor: AppTheme.cardDark,
                          labelStyle: TextStyle(color: mode == 'Teach' ? Colors.white : AppTheme.textGray),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Learn'),
                          selected: mode == 'Learn',
                          onSelected: (_) => setDialogState(() => mode = 'Learn'),
                          selectedColor: AppTheme.primaryPurple,
                          backgroundColor: AppTheme.cardDark,
                          labelStyle: TextStyle(color: mode == 'Learn' ? Colors.white : AppTheme.textGray),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Proficiency: ${percentage.toInt()}%", style: const TextStyle(color: Colors.white)),
                        Slider(
                          value: percentage,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          activeColor: AppTheme.primaryPurple,
                          inactiveColor: AppTheme.textGray,
                          onChanged: (val) {
                            setDialogState(() {
                              percentage = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: AppTheme.textGray)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    
                    List<Map<dynamic, dynamic>> updatedSkills = List.from(_skills);
                    Map<String, dynamic> newSkill = {
                      'name': nameController.text.trim(),
                      'description': descController.text.trim(),
                      'percentage': percentage.toInt(),
                      'mode': mode,
                    };

                    if (index != null) {
                      updatedSkills[index] = newSkill;
                    } else {
                      updatedSkills.add(newSkill);
                    }

                    await _userRef.set(updatedSkills);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteSkill(int index) async {
    List<Map<dynamic, dynamic>> updatedSkills = List.from(_skills);
    updatedSkills.removeAt(index);
    await _userRef.set(updatedSkills);
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text("Please login to view skills.", style: TextStyle(color: Colors.white)));
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("My Skills", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text("Add your skills below so others can find and connect with you.", style: TextStyle(color: AppTheme.textGray)),
                const SizedBox(height: 24),
                
                Expanded(
                  child: _skills.isEmpty
                      ? const Center(child: Text("No skills added yet.", style: TextStyle(color: AppTheme.textGray)))
                      : ListView.builder(
                          itemCount: _skills.length,
                          itemBuilder: (context, index) {
                            final skill = _skills[index];
                            final name = skill['name'] ?? 'Unknown';
                            final description = skill['description'] ?? '';
                            final percentage = skill['percentage'] ?? 50;
                            final mode = skill['mode'] ?? 'Teach';

                            return Card(
                              color: AppTheme.cardDark,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              backgroundColor: AppTheme.primaryBlue,
                                              radius: 16,
                                              child: Icon(Icons.star, color: Colors.white, size: 16),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: AppTheme.textGray),
                                              onPressed: () => _showAddEditSkillDialog(skill, index),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 16),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                                              onPressed: () => _deleteSkill(index),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (description.toString().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(description, style: const TextStyle(color: AppTheme.textGray, fontSize: 14)),
                                    ],
                                    const SizedBox(height: 8),
                                    Chip(
                                      backgroundColor: mode == 'Teach' ? Colors.green : AppTheme.primaryBlue,
                                      label: Text(mode == 'Teach' ? 'Want to Teach' : 'Want to Learn', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: percentage / 100,
                                            backgroundColor: AppTheme.darkBg,
                                            color: AppTheme.primaryPurple,
                                            minHeight: 8,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text("$percentage%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryPurple,
        onPressed: () => _showAddEditSkillDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Skill", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
