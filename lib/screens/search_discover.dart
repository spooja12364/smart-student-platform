import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/public_profile.dart';

class SearchDiscover extends StatefulWidget {
  const SearchDiscover({super.key});

  @override
  State<SearchDiscover> createState() => _SearchDiscoverState();
}

class _SearchDiscoverState extends State<SearchDiscover> {
  String _searchQuery = "";
  String _filter = "Users"; // Users or Skills

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Discover", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by name, skill, college...",
                hintStyle: const TextStyle(color: AppTheme.textGray),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textGray),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFilterChip("Users"),
                const SizedBox(width: 10),
                _buildFilterChip("Skills"),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _filter == "Users" ? _buildUserResults() : _buildSkillResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textGray)),
      selected: isSelected,
      selectedColor: AppTheme.primaryPurple,
      backgroundColor: AppTheme.cardDark,
      onSelected: (val) {
        if (val) setState(() => _filter = label);
      },
    );
  }

  Widget _buildUserResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String name = (data['fullName'] ?? '').toString().toLowerCase();
          String college = (data['collegeName'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || college.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: const CircleAvatar(backgroundColor: AppTheme.primaryBlue, child: Icon(Icons.person, color: Colors.white)),
              title: Text(data['fullName'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(data['collegeName'] ?? "No college specified", style: const TextStyle(color: AppTheme.textGray)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(userId: docs[index].id)));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSkillResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('skills').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String skill = (data['skillName'] ?? '').toString().toLowerCase();
          String cat = (data['category'] ?? '').toString().toLowerCase();
          return skill.contains(_searchQuery) || cat.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: AppTheme.glassBoxDecoration,
              child: ListTile(
                title: Text(data['skillName'] ?? "", style: const TextStyle(color: Colors.white)),
                subtitle: Text(data['category'] ?? "", style: const TextStyle(color: AppTheme.textGray)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ),
            );
          },
        );
      },
    );
  }
}
