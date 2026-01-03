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

  void handleSubmit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        if (widget.isLoginPage) {
          // LOGIN MODE
          await _auth.logIn(email.text, password.text);

          // After successful login, navigate
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        } else {
          // SIGNUP MODE
          await _auth.signUp(email.text, password.text);

          // If signup works, show confirmation message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Signup successful! Please check your email to confirm your account.",
              ),
            ),
          );

          // Optionally redirect to login page after signup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LogInPage()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.isLoginPage;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;

          double formWidth = screenWidth < 600
              ? screenWidth * 0.8
              : (screenWidth * 0.8).clamp(400, 600);

          return Center(
            child: SingleChildScrollView(
              child: SizedBox(
                width: formWidth,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment(1.2, 0.6),
                        children: [
                          Icon(Icons.cloud, size: 100, color: Colors.blue),
                          Text(
                            "App",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 23,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isLogin ? "Welcome Back" : "Let's create an account",
                        style: TextStyle(
                          fontSize: 32,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: 30),

                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextFormField(
                              controller: email,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              validator: (input) {
                                if (input == null || input.isEmpty) {
                                  return 'Email is required';
                                }
                                return isValidEmail(input)
                                    ? null
                                    : "Invalid email";
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 20),
                            // Show password field only if signup OR login requires it
                            if (!isLogin || true)
                              TextFormField(
                                controller: password,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                ),
                                obscureText: true,
                                validator: (input) {
                                  if (isLogin) {
                                    // Login page: no password validation, only check empty
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
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                              ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => handleSubmit(context),
                              child: Text(isLogin ? "Log In" : "Sign Up"),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => isLogin
                                        ? const SignUpPage()
                                        : const LogInPage(),
                                  ),
                                );
                              },
                              child: Text(
                                isLogin
                                    ? "Don't have an account? Sign Up"
                                    : "Already have an account? Log In",
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
        },
      ),
    );
  }
}
