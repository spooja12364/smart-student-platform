import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/chat_detail.dart';

class Connections extends StatefulWidget {
  const Connections({super.key});

  @override
  State<Connections> createState() => _ConnectionsState();
}

class _ConnectionsState extends State<Connections> with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  
  List<Map<dynamic, dynamic>> _allUsers = [];
  List<Map<dynamic, dynamic>> _searchResults = [];
  Map<String, dynamic> _myConnections = {};
  
  String _searchQuery = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (currentUser != null) {
      _fetchData();
    }
  }

  void _fetchData() {
    // Listen to all users
    FirebaseDatabase.instance.ref("users").onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> usersList = [];
        data.forEach((key, value) {
          if (key != currentUser!.uid) {
            value['uid'] = key;
            usersList.add(value);
          }
        });
        setState(() {
          _allUsers = usersList;
          _updateSearchResults();
          _isLoading = false;
        });
      }
    });

    // Listen to my connections
    FirebaseDatabase.instance.ref("connections/${currentUser!.uid}").onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        setState(() {
          _myConnections = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      } else {
        setState(() {
          _myConnections = {};
        });
      }
    });
  }

  void _updateSearchResults() {
    if (_searchQuery.isEmpty) {
      _searchResults = _allUsers;
    } else {
      _searchResults = _allUsers.where((u) {
        final skills = u['skills'];
        if (skills is List) {
          for (var s in skills) {
            if (s is Map && s['name'] != null) {
              final skillName = s['name'].toString().toLowerCase();
              if (skillName.contains(_searchQuery.toLowerCase())) {
                return true;
              }
            } else if (s is String) {
              if (s.toLowerCase().contains(_searchQuery.toLowerCase())) {
                return true;
              }
            }
          }
        } else if (skills is String) {
           return skills.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        return false;
      }).toList();
    }
  }

  Future<void> _sendRequest(String targetUid) async {
    await FirebaseDatabase.instance.ref("connections/$targetUid/requests/${currentUser!.uid}").set(true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request sent!")));
  }

  Future<void> _acceptRequest(String requesterUid) async {
    // Add to my accepted
    await FirebaseDatabase.instance.ref("connections/${currentUser!.uid}/accepted/$requesterUid").set(true);
    // Remove from my requests
    await FirebaseDatabase.instance.ref("connections/${currentUser!.uid}/requests/$requesterUid").remove();
    
    // Add me to their accepted
    await FirebaseDatabase.instance.ref("connections/$requesterUid/accepted/${currentUser!.uid}").set(true);
  }

  Future<void> _rejectRequest(String requesterUid) async {
    await FirebaseDatabase.instance.ref("connections/${currentUser!.uid}/requests/$requesterUid").remove();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text("Please login.", style: TextStyle(color: Colors.white)));
    }

    final requestsMap = _myConnections['requests'] as Map? ?? {};
    final acceptedMap = _myConnections['accepted'] as Map? ?? {};
    
    final requestUsers = _allUsers.where((u) => requestsMap.containsKey(u['uid'])).toList();
    final connectedUsers = _allUsers.where((u) => acceptedMap.containsKey(u['uid'])).toList();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _updateSearchResults();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search by skill...",
                  hintStyle: const TextStyle(color: AppTheme.textGray),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textGray),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryPurple,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textGray,
              tabs: [
                const Tab(text: "Discover"),
                Tab(text: "Requests (${requestUsers.length})"),
                Tab(text: "Connected (${connectedUsers.length})"),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildUserList(_searchResults, "Discover"),
              _buildUserList(requestUsers, "Requests"),
              _buildUserList(connectedUsers, "Connected"),
            ],
          ),
    );
  }

  Widget _buildUserList(List<Map<dynamic, dynamic>> list, String type) {
    if (list.isEmpty) {
      return Center(child: Text("No users found.", style: const TextStyle(color: AppTheme.textGray)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final u = list[index];
        final String uid = u['uid'];
        final String name = u['name'] ?? u['username'] ?? 'Student';
        
        String skillsStr = 'No skills listed';
        if (u['skills'] is List) {
          final skillsList = (u['skills'] as List)
              .map((s) => s is Map ? s['name'].toString() : s.toString())
              .toList();
          if (skillsList.isNotEmpty) {
            skillsStr = skillsList.join(', ');
          }
        } else if (u['skills'] is String && u['skills'].toString().isNotEmpty) {
          skillsStr = u['skills'].toString();
        }

        final String bio = (u['bio']?.toString().isNotEmpty ?? false) ? u['bio'].toString() : 'No bio available.';

        final acceptedMap = _myConnections['accepted'] as Map? ?? {};
        final isConnected = acceptedMap.containsKey(uid);

        return Card(
          color: AppTheme.cardDark,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: const CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Skills: $skillsStr', style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(bio, style: const TextStyle(color: AppTheme.textGray, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            trailing: _buildActionButtons(uid, type, isConnected, name),
            onTap: isConnected ? () {
              final String myUid = currentUser!.uid;
              final List<String> uids = [myUid, uid];
              uids.sort();
              final String chatId = uids.join('_');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailPage(chatId: chatId, otherUserId: uid, otherUserName: name),
                ),
              );
            } : null,
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(String uid, String type, bool isConnected, [String? name]) {
    if (type == "Connected" || isConnected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Chip(
            label: Text("Connected", style: TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: Colors.green,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chat, color: AppTheme.primaryPurple),
            onPressed: () {
              final String myUid = currentUser!.uid;
              final List<String> uids = [myUid, uid];
              uids.sort();
              final String chatId = uids.join('_');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailPage(chatId: chatId, otherUserId: uid, otherUserName: name),
                ),
              );
            },
          ),
        ],
      );
    }

    if (type == "Requests") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _acceptRequest(uid),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            onPressed: () => _rejectRequest(uid),
          ),
        ],
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => _sendRequest(uid),
      child: const Text("Connect", style: TextStyle(color: Colors.white)),
    );
  }
}
