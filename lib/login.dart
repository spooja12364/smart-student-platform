import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_student_platform/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;
  bool _hasShownRouteMessage = false;

  Future<void> loginUser() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: emailController.text.trim(),
  password: passwordController.text.trim(),
);

TextInput.finishAutofillContext();
if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // GO TO DASHBOARD
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });

      String message = "Login Failed";

      if (e.code == 'user-not-found') {
        message = "No user found";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email";
      }
      else if (e.code == 'invalid-credential') {
        message = "Invalid email or password";
     }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasShownRouteMessage) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['message'] is String) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(args['message'] as String),
            backgroundColor: Colors.green,
          ),
        );
      });
      _hasShownRouteMessage = true;
    }
  }

  Future<void> resetPassword() async {
    final resetEmailController = TextEditingController(text: emailController.text);
    
    showDialog(
      context: context,
      builder: (context) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Reset Password", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Enter your email address and we will send you a password reset link.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Email Address",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isSending ? null : () async {
                    if (resetEmailController.text.trim().isEmpty) return;
                    setDialogState(() => isSending = true);
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: resetEmailController.text.trim());
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset email sent! Check your inbox.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                    } on FirebaseAuthException catch (e) {
                      setDialogState(() => isSending = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                    }
                  },
                  child: isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Send Link", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget buildField({
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextField(
        autofillHints: isPassword
    ? const [AutofillHints.password]
    : const [AutofillHints.email],

keyboardType: isPassword
    ? TextInputType.visiblePassword
    : TextInputType.emailAddress,
        controller: controller,
        obscureText: isPassword ? hidePassword : false,
        decoration: InputDecoration(
          hintText: hint,

          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Colors.deepPurple,
              width: 2,
            ),
          ),

          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.login, size: 58, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Smart Student Login",
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Login to your student dashboard and continue collaborating.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGray, fontSize: 15),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassBoxDecoration,
                  child: Column(
                    children: [
                      buildField(hint: "Email", controller: emailController),
                      buildField(hint: "Password", controller: passwordController, isPassword: true),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: resetPassword,
                          child: const Text("Forgot Password?", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isLoading ? null : loginUser,
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("New here? ", style: TextStyle(color: AppTheme.textGray)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: const Text("Create account", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}