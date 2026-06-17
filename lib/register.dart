import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_student_platform/theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final captchaController = TextEditingController();
  final cityController = TextEditingController();
  final skillsController = TextEditingController();
  final bioController = TextEditingController();

  String? _errorMessage;
  bool otpSent = false;
  bool otpVerified = false;
  bool agree = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  String generatedOtp = '';
  String captchaText = '';
  bool? _isUsernameAvailable;

  String get _otpKey => emailController.text.trim().replaceAll('.', ',');

  @override
  void initState() {
    super.initState();
    generateCaptcha();
  }

  @override
  void dispose() {
    _pageController.dispose();
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    captchaController.dispose();
    cityController.dispose();
    skillsController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void _setError(String? message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
  }

  void generateCaptcha() {
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    captchaText = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    captchaController.clear();
  }

  Future<void> _checkUsernameAvailability(String value) async {
    final username = value.trim();
    if (username.isEmpty) {
      setState(() => _isUsernameAvailable = null);
      return;
    }

    setState(() => _isUsernameAvailable = null);

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users')
          .orderByChild('username')
          .equalTo(username)
          .once();
      setState(() => _isUsernameAvailable = snapshot.snapshot.value == null);
    } catch (_) {
      setState(() => _isUsernameAvailable = true); // Fallback to true if DB rules block read
    }
  }

  Future<void> sendOTP() async {
    _setError(null);

    if (emailController.text.trim().isEmpty || fullNameController.text.trim().isEmpty) {
      _setError('Please fill in your name and email before sending OTP.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool emailExists = false;
      try {
        final emailSnapshot = await FirebaseDatabase.instance
            .ref('users')
            .orderByChild('email')
            .equalTo(emailController.text.trim())
            .once();
        if (emailSnapshot.snapshot.value != null) emailExists = true;
      } catch (_) {}

      try {
        final firestoreSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: emailController.text.trim())
            .get();
        if (firestoreSnapshot.docs.isNotEmpty) emailExists = true;
      } catch (_) {}

      if (emailExists) {
        _setError('Email already exists. Please use another email.');
        return;
      }

      generatedOtp = (100000 + Random().nextInt(900000)).toString();

      try {
        await FirebaseDatabase.instance.ref('otpCodes/$_otpKey').set({
          'otp': generatedOtp,
          'name': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'sentAt': ServerValue.timestamp,
        });
      } catch (_) {}

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': 'service_hrowx0v',
          'template_id': 'template_p4q3r8i',
          'user_id': '0SSH8Hp7Vq8L7F_p-',
          'template_params': {
            'user_name': fullNameController.text.trim(),
            'otp_code': generatedOtp,
            'to_email': emailController.text.trim(),
          },
        }),
      ).timeout(const Duration(seconds: 20));

      setState(() {
        otpSent = true;
        otpVerified = false;
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to your email')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP generated, but email delivery returned ${response.statusCode}. Use OTP: $generatedOtp')),
          );
        }
      }
    } catch (e) {
      setState(() {
        otpSent = true;
        otpVerified = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Email Service Unavailable'),
            content: Text('We could not send the OTP via email right now.\n\nPlease use this OTP to proceed: $generatedOtp'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> verifyOTP() async {
    _setError(null);

    final enteredOtp = otpController.text.trim();
    if (enteredOtp.isEmpty) {
      _setError('Please enter the OTP.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (enteredOtp == generatedOtp) {
        setState(() {
          otpVerified = true;
        });
        try {
          await FirebaseDatabase.instance.ref('otpCodes/$_otpKey').remove();
        } catch (_) {}
      } else {
        _setError('Wrong OTP');
      }
    } catch (e) {
      _setError('Verification failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (fullNameController.text.trim().isEmpty ||
          usernameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty) {
        _setError('Please fill in your full name, username, and email.');
        return;
      }
      if (_isUsernameAvailable != true) {
        _setError('Please wait for username availability check or choose an available username.');
        return;
      }
    } else if (_currentStep == 1) {
      if (!otpVerified) {
        _setError('Please generate and verify OTP before proceeding.');
        return;
      }
    } else if (_currentStep == 2) {
      if (passwordController.text.length < 6) {
        _setError('Password must be at least 6 characters.');
        return;
      }
      if (passwordController.text != confirmPasswordController.text) {
        _setError('Passwords do not match.');
        return;
      }
      if (captchaController.text.trim().toUpperCase() != captchaText.toUpperCase()) {
        _setError('Wrong Captcha. Try again.');
        generateCaptcha();
        return;
      }
      if (!agree) {
        _setError('You must agree to the Terms & Conditions.');
        return;
      }
    } else if (_currentStep == 3) {
      _submitRegistration();
      return;
    }

    _setError(null);
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    _setError(null);
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitRegistration() async {
    if (skillsController.text.trim().isEmpty) {
      _setError('Please add at least one skill.');
      return;
    }

    if (bioController.text.trim().isNotEmpty) {
      final words = bioController.text.trim().split(RegExp(r'\s+'));
      if (words.length < 5) {
        _setError('Bio must be at least 5 words.');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final uid = userCredential.user!.uid;
      final skills = skillsController.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .map((skill) => {
                'name': skill,
                'percentage': 50,
                'description': '',
              })
          .toList();

      final profileName = fullNameController.text.trim();
      final profileEmail = emailController.text.trim();
      final profileUsername = usernameController.text.trim();

      try {
        await FirebaseDatabase.instance.ref('users/$uid').set({
          'uid': uid,
          'name': profileName,
          'fullName': profileName,
          'username': profileUsername,
          'email': profileEmail,
          'phone': '',
          'college': '',
          'department': '',
          'year': '',
          'city': cityController.text.trim(),
          'bio': bioController.text.trim(),
          'profileImage': '',
          'profilePicture': '',
          'skills': skills,
          'createdAt': ServerValue.timestamp,
        });
      } catch (_) {}

      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'name': profileName,
          'fullName': profileName,
          'username': profileUsername,
          'email': profileEmail,
          'bio': bioController.text.trim(),
          'profileImage': '',
          'profilePicture': '',
          'skills': skills,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login', arguments: {
        'message': 'Registration Successful! Please login.',
      });
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Registration failed.');
    } catch (e) {
      _setError('Registration failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget buildField(
    String hint,
    TextEditingController controller, {
    bool isOptional = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: isOptional ? '$hint (Optional - Skip if you want)' : hint,
          hintStyle: const TextStyle(color: AppTheme.textGray),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField(
    String hint,
    TextEditingController controller,
    bool hide,
    VoidCallback toggle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: hide,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textGray),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
          ),
          suffixIcon: IconButton(
            icon: Icon(hide ? Icons.visibility_off : Icons.visibility, color: AppTheme.textGray),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineError() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: _errorMessage != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _previousStep,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentStep >= index ? AppTheme.primaryPurple : Colors.white24,
              ),
            );
          }),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer(String title, String subtitle, List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: AppTheme.textGray),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassBoxDecoration,
            child: Column(
              children: [
                _buildInlineError(),
                ...children,
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryPurple),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _nextStep,
                          child: Text(
                            _currentStep == 3 ? 'COMPLETE REGISTRATION' : 'NEXT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                if (_currentStep == 0) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      'Already have an account? Login here',
                      style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _buildStepContainer(
      'Who are you?',
      'Let\'s get to know your basic details.',
      [
        buildField('Full Name', fullNameController),
        buildField(
          'Username',
          usernameController,
          onChanged: (val) {
            _checkUsernameAvailability(val);
          },
        ),
        _buildUsernameValidationText(),
        buildField(
          'Email',
          emailController,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildUsernameValidationText() {
    if (usernameController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isUsernameAvailable == null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text(
          'Checking username availability...',
          style: TextStyle(color: AppTheme.textGray, fontSize: 13),
        ),
      );
    }

    if (_isUsernameAvailable == true) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Username available!',
              style: TextStyle(color: Colors.green, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: Colors.redAccent),
          SizedBox(width: 8),
          Text(
            'Username is already taken.',
            style: TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _buildStepContainer(
      'Verification',
      'We need to verify your email address.',
      [
        if (!otpSent && !otpVerified)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isLoading ? null : sendOTP,
              child: const Text('GENERATE OTP', style: TextStyle(color: Colors.white)),
            ),
          ),
        if (otpSent && !otpVerified) ...[
          buildField('Enter OTP', otpController),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: verifyOTP,
              child: const Text('VERIFY OTP', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
        if (otpVerified)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Email Verified Successfully!',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStep3() {
    return _buildStepContainer(
      'Security',
      'Secure your account with a strong password.',
      [
        buildPasswordField(
          'Password (min 6 chars)',
          passwordController,
          hidePassword,
          () => setState(() => hidePassword = !hidePassword),
        ),
        buildPasswordField(
          'Confirm Password',
          confirmPasswordController,
          hideConfirmPassword,
          () => setState(() => hideConfirmPassword = !hideConfirmPassword),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              const Text('Security Check', style: TextStyle(color: AppTheme.textGray)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  captchaText,
                  style: const TextStyle(
                    fontSize: 32,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              buildField('Enter Captcha Above', captchaController),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: agree,
              activeColor: AppTheme.primaryPurple,
              onChanged: (v) => setState(() => agree = v ?? false),
            ),
            const Expanded(
              child: Text(
                'I agree to the Terms & Conditions',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return _buildStepContainer(
      'Profile Setup',
      'Tell us a bit about yourself.',
      [
        buildField('City', cityController, isOptional: true),
        buildField('Skills / Interests (Comma separated)', skillsController),
        buildField('Short Bio (Min 5 words)', bioController, isOptional: true, maxLines: 3),
        const SizedBox(height: 16),
      ],
    );
  }
}
