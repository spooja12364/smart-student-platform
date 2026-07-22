import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/dashboard_home.dart';
import 'package:smart_student_platform/screens/my_skills.dart';
import 'package:smart_student_platform/screens/connections.dart';
import 'package:smart_student_platform/screens/chat_list.dart';
import 'package:smart_student_platform/screens/profile.dart';
import 'package:smart_student_platform/screens/notifications.dart';
import 'package:smart_student_platform/screens/ai_chat.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  late final List<Widget> _pages = [
    DashboardHome(onNavigate: (index) {
      setState(() {
        _selectedIndex = index;
      });
    }),
    const MySkills(),
    const Connections(),
    const ChatListPage(),
    const ProfilePage(),
  ];

  StreamSubscription? _notifSubscription;
  bool _initialLoadComplete = false;
  int _unreadChatCount = 0;

  @override
  void initState() {
    super.initState();
    _listenForNotifications();
  }

  void _listenForNotifications() {
    if (user == null) return;
    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user!.uid)
        .snapshots()
        .listen((snapshot) {
          
      int unreadChats = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'message' && data['read'] == false) {
          unreadChats++;
        }
      }
      if (mounted) {
        setState(() {
          _unreadChatCount = unreadChats;
        });
      }

      if (!_initialLoadComplete) {
        _initialLoadComplete = true;
        return;
      }
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['title'] != null) {
            _showNotificationSnackbar(data['title'], data['body'] ?? '');
          }
        }
      }
    });
  }

  void _showNotificationSnackbar(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            if (body.isNotEmpty) Text(body, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        backgroundColor: AppTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()));
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Smart Student", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()));
            },
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) async {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 3 && user != null) {
               // Mark all message notifications as read
               final unreadDocs = await FirebaseFirestore.instance.collection('notifications')
                   .where('userId', isEqualTo: user!.uid)
                   .where('type', isEqualTo: 'message')
                   .where('read', isEqualTo: false)
                   .get();
               for (var doc in unreadDocs.docs) {
                 doc.reference.update({'read': true});
               }
            }
          },
          backgroundColor: AppTheme.cardDark,
          selectedItemColor: AppTheme.primaryPurple,
          unselectedItemColor: AppTheme.textGray,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Skills'),
            const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Connections'),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: _unreadChatCount > 0,
                label: Text(_unreadChatCount.toString()),
                child: const Icon(Icons.chat),
              ),
              label: 'Chats',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AiChatPage()));
        },
        backgroundColor: AppTheme.primaryBlue,
        elevation: 8,
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.cardDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? "User",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text("Profile", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // Close drawer
              setState(() {
                _selectedIndex = 4; // Assuming 4 is Profile
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.white),
            title: const Text("Add Skills", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 1; // Assuming 1 is Skills
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.white),
            title: const Text("Connections", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 2; // Assuming 2 is Connections/Chat
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.white),
            title: const Text("Chats", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 3;
              });
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
