import 'package:flutter/material.dart';
import 'package:cloud_app/HomePage/myHomePage.dart';
import 'package:cloud_app/LoginSignupPage/LoginSignupCom/LoginPage.dart';
import 'package:cloud_app/LoginSignupPage/LoginSignupCom/SignUpPage.dart';
import 'package:cloud_app/auth_service.dart';

class Loginsignuppage extends StatefulWidget {
  const Loginsignuppage({super.key, required this.isLoginPage});

  final bool isLoginPage;

  @override
  State<Loginsignuppage> createState() => _Logininsignuppagestate();
}

class _Logininsignuppagestate extends State<Loginsignuppage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final _auth = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    if (password.length < 6) return false;
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    return hasUpperCase && hasLowerCase;
  }

  Future<void> _handleSubmit() async {
    if (!mounted) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isLoginPage) {
        await _auth.logIn(email.text.trim(), password.text.trim());
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
      } else {
        await _auth.signUp(email.text.trim(), password.text.trim());
        if (!mounted) return;

        // Show confirmation message
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text("Signup successful! Please check your email."),
            duration: Duration(seconds: 3),
          ),
        );

        // Redirect to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LogInPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.isLoginPage;
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
                // Logo
                Icon(
                  Icons.cloud,
                  size: isSmallScreen ? 56 : 64,
                  color: Colors.blue[700],
                ),

                SizedBox(height: isSmallScreen ? 16 : 24),

                // Title
                Text(
                  isLogin ? "Welcome Back" : "Create Account",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 24 : 32),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      TextFormField(
                        controller: email,
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
                        validator: (input) {
                          if (input == null || input.isEmpty) {
                            return 'Email is required';
                          }
                          return isValidEmail(input) ? null : "Invalid email";
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Password Field
                      TextFormField(
                        controller: password,
                        decoration: InputDecoration(
                          labelText: 'Password',
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
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (input) {
                          if (isLogin) {
                            if (input == null || input.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          } else {
                            if (input == null || input.isEmpty) {
                              return 'Password is required';
                            }
                            return isValidPassword(input)
                                ? null
                                : 'Password must have upper & lower case, min 6 chars';
                          }
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 48 : 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 1,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  isLogin ? "Sign In" : "Sign Up",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Switch Button
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => isLogin
                                        ? const SignUpPage()
                                        : const LogInPage(),
                                  ),
                                );
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                        ),
                        child: Text(
                          isLogin
                              ? "Don't have an account? Sign Up"
                              : "Already have an account? Sign In",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 24 : 32),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                      ),
                      child: Text(
                        "or",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 20 : 24),

                // Google Button
                Container(
                  height: isSmallScreen ? 46 : 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _isLoading ? null : () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'google_image/google.png',
                            width: 30,
                            height: 30,
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Text(
                            'Sign in with Google',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
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
