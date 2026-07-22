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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Discover", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            SizedBox(height: 16),
            TextField(
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Search by name, skill, college...",
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            SizedBox(height: 16),
            Row(
              children: [
                _buildFilterChip("Users"),
                SizedBox(width: 10),
                _buildFilterChip("Skills"),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: _filter == "Users" ? _buildUserResults() : _buildSkillResults(),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant)),
      selected: isSelected,
      selectedColor: AppTheme.primaryPurple,
      backgroundColor: Theme.of(context).cardColor,
      onSelected: (val) {
        if (val) setState(() => _filter = label);
      },
    );
  }

  Widget _buildUserResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
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
              leading: CircleAvatar(backgroundColor: AppTheme.primaryBlue, child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface)),
              title: Text(data['fullName'] ?? "Unknown", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
              subtitle: Text(data['collegeName'] ?? "No college specified", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
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
              decoration: AppTheme.glassBoxDecoration(context),
              child: ListTile(
                title: Text(data['skillName'] ?? "", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                subtitle: Text(data['category'] ?? "", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface, size: 16),
              ),
            );
          },
        );
      },
    );
  }
}
