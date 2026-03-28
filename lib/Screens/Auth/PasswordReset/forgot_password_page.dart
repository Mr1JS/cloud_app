import 'package:cloud_app/Screens/Auth/Utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_app/services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isLoading = true);

    try {
      await _auth.sendOTP(_email.text.trim());
      if (!mounted) return;
      Get.toNamed('/verify-otp', arguments: _email.text.trim());
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
                  "Forgot Password",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                Text(
                  "We'll send a 6-digit code to your email.",
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
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
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
                        ),
                        validator: Validators.email,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 48 : 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSendOtp,
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
                                  "Send Code",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Get.offAllNamed('/'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                        ),
                        child: Text(
                          "Back to Sign In",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w500,
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
