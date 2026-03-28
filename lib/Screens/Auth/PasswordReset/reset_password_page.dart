import 'package:cloud_app/Screens/Auth/Utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_app/services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isLoading = true);

    try {
      await _auth.updatePassword(_password.text.trim());
      if (_auth.session == null) {
        throw Exception('Session expired. Please restart password reset.');
      }
      if (!mounted) return;
      await _auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text("Password updated successfully!"),
          duration: Duration(seconds: 3),
        ),
      );
      Get.offAllNamed('/');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('message: ')
          ? e.toString().split('message: ')[1].split(',')[0]
          : 'Something went wrong';
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen
                ? MediaQuery.of(context).size.width * 0.9
                : 420,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20 : 32,
            vertical: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/splash_screen/cloud_icon.png',
                  width: isSmallScreen ? 56 : 64,
                  height: isSmallScreen ? 56 : 64,
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                Text(
                  "New Password",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                Text(
                  "Choose a strong password for your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 24 : 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // New password
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue[700]!,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(
                            isSmallScreen ? 14 : 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: isSmallScreen ? 20 : 24,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (input) =>
                            Validators.password(input, isLogin: false),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      // Confirm password
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue[700]!,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(
                            isSmallScreen ? 14 : 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: isSmallScreen ? 20 : 24,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (input) {
                          if (input == null || input.isEmpty) {
                            return 'Please confirm your password';
                          }
                          return input == _password.text
                              ? null
                              : 'Passwords do not match';
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 48 : 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 1,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  "Update Password",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
