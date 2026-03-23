import 'package:flutter/material.dart';
import 'package:cloud_app/Screens/Auth/Widgets/login_signup_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  @override
  Widget build(BuildContext context) {
    return const Loginsignuppage(isLoginPage: false);
  }
}
