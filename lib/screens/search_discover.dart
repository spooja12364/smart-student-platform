import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/public_profile.dart';

class SearchDiscover extends StatefulWidget {
  const SearchDiscover({super.key});

  @override
  State<SearchDiscover> createState() => _SearchDiscoverState();
}

class _SearchDiscoverState extends State<SearchDiscover> {
  String _searchQuery = "";
  Map<String, List<String>> _userSkillsMap = {};

  @override
  void initState() {
    super.initState();
    _fetchUserSkills();
  }

  void _fetchUserSkills() {
    FirebaseDatabase.instance.ref("users").onValue.listen((event) {
       if (event.snapshot.value != null && mounted) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          Map<String, List<String>> newSkills = {};
          data.forEach((key, value) {
             if (value is Map && value['skills'] is List) {
                 newSkills[key.toString()] = (value['skills'] as List).map((e) {
                    if (e is Map) return (e['name'] ?? '').toString();
                    return e.toString();
                 }).toList();
             }
          });
          setState(() {
             _userSkillsMap = newSkills;
          });
       }
    });
  }

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
                hintText: "Search by skill...",
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
            SizedBox(height: 20),
            Expanded(
              child: _buildUserResults(),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildUserResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          List<String> userSkills = _userSkillsMap[doc.id] ?? [];
          return userSkills.any((skill) => skill.toLowerCase().contains(_searchQuery));
        }).toList();

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            List<String> skills = _userSkillsMap[docs[index].id] ?? [];
            String skillsText = skills.isEmpty ? "No skills added" : skills.take(3).join(", ");
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: CircleAvatar(backgroundColor: AppTheme.primaryBlue, child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface)),
              title: Text(data['fullName'] ?? "Unknown", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
              subtitle: Text(skillsText, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(userId: docs[index].id)));
              },
            );
          },
        );
      },
    );
  }

}
