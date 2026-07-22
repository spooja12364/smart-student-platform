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
              backgroundColor: Theme.of(context).cardColor,
              title: Text(existingSkill == null ? "Add Skill" : "Edit Skill", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Skill Name",
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        hintText: "e.g. Flutter, Firebase, AI",
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Description",
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        hintText: "Briefly describe your experience",
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text('Teach'),
                          selected: mode == 'Teach',
                          onSelected: (_) => setDialogState(() => mode = 'Teach'),
                          selectedColor: AppTheme.primaryPurple,
                          backgroundColor: Theme.of(context).cardColor,
                          labelStyle: TextStyle(color: mode == 'Teach' ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        SizedBox(width: 12),
                        ChoiceChip(
                          label: Text('Learn'),
                          selected: mode == 'Learn',
                          onSelected: (_) => setDialogState(() => mode = 'Learn'),
                          selectedColor: AppTheme.primaryPurple,
                          backgroundColor: Theme.of(context).cardColor,
                          labelStyle: TextStyle(color: mode == 'Learn' ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Proficiency: ${percentage.toInt()}%", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        Slider(
                          value: percentage,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          activeColor: AppTheme.primaryPurple,
                          inactiveColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                  child: Text("Save", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
      return Center(child: Text("Please login to view skills.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("My Skills", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 8),
                Text("Add your skills below so others can find and connect with you.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                SizedBox(height: 24),
                
                Expanded(
                  child: _skills.isEmpty
                      ? Center(child: Text("No skills added yet.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                      : ListView.builder(
                          itemCount: _skills.length,
                          itemBuilder: (context, index) {
                            final skill = _skills[index];
                            final name = skill['name'] ?? 'Unknown';
                            final description = skill['description'] ?? '';
                            final percentage = skill['percentage'] ?? 50;
                            final mode = skill['mode'] ?? 'Teach';

                            return Card(
                              color: Theme.of(context).cardColor,
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
                                            CircleAvatar(
                                              backgroundColor: AppTheme.primaryBlue,
                                              radius: 16,
                                              child: Icon(Icons.star, color: Theme.of(context).colorScheme.onSurface, size: 16),
                                            ),
                                            SizedBox(width: 12),
                                            Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                              onPressed: () => _showAddEditSkillDialog(skill, index),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            SizedBox(width: 16),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.redAccent),
                                              onPressed: () => _deleteSkill(index),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (description.toString().isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Text(description, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                                    ],
                                    SizedBox(height: 8),
                                    Chip(
                                      backgroundColor: mode == 'Teach' ? Colors.green : AppTheme.primaryBlue,
                                      label: Text(mode == 'Teach' ? 'Want to Teach' : 'Want to Learn', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: percentage / 100,
                                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                            color: AppTheme.primaryPurple,
                                            minHeight: 8,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text("$percentage%", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
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
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface),
        label: Text("Add Skill", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ),
    );
  }
}
