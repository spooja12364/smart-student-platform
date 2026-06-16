import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart';
import 'welcome.dart';
import 'login.dart';
import 'register.dart';
import 'package:smart_student_platform/screens/profile.dart';
import 'package:smart_student_platform/screens/my_skills.dart';
import 'package:smart_student_platform/screens/connections.dart';
import 'package:smart_student_platform/screens/chat_list.dart';
import 'package:smart_student_platform/screens/group_chat_list.dart';
import 'package:smart_student_platform/screens/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Student Platform',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: FirebaseAuth.instance.currentUser != null ? '/dashboard' : '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/profile': (context) => const ProfilePage(),
        '/my_skills': (context) => const MySkillsPage(),
        '/connections': (context) => const ConnectionsPage(),
        '/chats': (context) => const ChatListPage(),
        '/groups': (context) => const GroupChatListPage(),
        '/notifications': (context) => const NotificationsPage(),
      },
    );
  }
}