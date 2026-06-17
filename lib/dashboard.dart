import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_student_platform/theme.dart';
import 'package:smart_student_platform/screens/dashboard_home.dart';
import 'package:smart_student_platform/screens/my_skills.dart';
import 'package:smart_student_platform/screens/connections.dart';
import 'package:smart_student_platform/screens/chat_list.dart';
import 'package:smart_student_platform/screens/profile.dart';

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
    const MySkills(),
    const Connections(),
    const ChatListPage(),
    const ProfilePage(),
  ];

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
            onPressed: () {},
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
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Skills'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Connections'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
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
