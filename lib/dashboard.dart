import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/dashboard_home.dart';
import 'package:smart_student_platform/screens/my_skills.dart';
import 'package:smart_student_platform/screens/ai_matching.dart';
import 'package:smart_student_platform/screens/connections.dart';
import 'package:smart_student_platform/screens/chat_list.dart';
import 'package:smart_student_platform/screens/group_chat_list.dart';
import 'package:smart_student_platform/screens/search_discover.dart';
import 'package:smart_student_platform/screens/notifications.dart';
import 'package:smart_student_platform/screens/profile.dart';
import 'package:smart_student_platform/login.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  final List<Widget> _pages = [
    const DashboardHome(),
    const SearchDiscover(),
    const AIMatching(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Smart Student",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
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
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: AppTheme.cardDark,
          selectedItemColor: AppTheme.primaryPurple,
          unselectedItemColor: AppTheme.textGray,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.search), label: 'Discover'),
            BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome), label: 'Match'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
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
                  child:
                      Icon(Icons.person, size: 40, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? "User",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          _drawerItem(
              Icons.star,
              "My Skills",
              () => Navigator.pushNamed(context, '/my_skills')),
          _drawerItem(
              Icons.people,
              "Connections",
              () => Navigator.pushNamed(context, '/connections')),
          _drawerItem(
              Icons.chat,
              "Chats",
              () => Navigator.pushNamed(context, '/chats')),
          _drawerItem(
              Icons.groups,
              "Groups",
              () => Navigator.pushNamed(context, '/groups')),
          const Divider(color: Colors.white24),
          _drawerItem(Icons.logout, "Logout", () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          }, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap,
      {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
