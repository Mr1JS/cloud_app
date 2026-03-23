import 'package:flutter/material.dart';
import 'package:cloud_app/Screens/Auth/Widgets/login_signup_page.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  @override
  Widget build(BuildContext context) {
    return const Loginsignuppage(isLoginPage: true);
  }
}
