import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    if (_isSignUp && _nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        // 1. Create Auth User
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. Create Firestore Document
        if (credential.user != null) {
          await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
            'fullName': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'wardNumber': 'Ward 195', // Default ward
            'ecoPoints': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Sign In
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: Color(0xFFF1F8E9), shape: BoxShape.circle),
                  child: const Icon(Icons.recycling_rounded, size: 64, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _isSignUp ? "Create Account" : AppStrings.welcomeBack,
                style: GoogleFonts.plusJakartaSans(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp ? "Join the green movement today" : AppStrings.signInToContinue, 
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 48),
              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock_outline_rounded)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(_isSignUp ? "Sign Up" : AppStrings.signIn),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp ? "Already have an account? Sign In" : "New user? Create an account",
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
