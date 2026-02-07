import 'package:cloud_app/Themes/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_app/Screens/Auth/login_page.dart';
import 'package:cloud_app/Screens/Home/home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before loading .env
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initialize Supabase with --> URL and anon key
  await Supabase.initialize(
    url: dotenv.get('url'),
    anonKey: dotenv.get('anonKey'),
  );

  // App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: UiTheme.lightTheme,
      darkTheme: UiTheme.darkTheme,
      themeMode: ThemeMode.system, // System says dark or light mode
      // Listen to auth state changes and show --> login page or the home page
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;

          // Session is null --> means user is not logged in --> show login page
          if (session == null) {
            return const LogInPage();
          }
          // Session exists --> user is logged in --> show home page
          return MyHomePage();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
