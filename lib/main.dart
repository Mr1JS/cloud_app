import 'package:cloud_app/Theme/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_app/LoginSignupPage/LoginSignupCom/LoginPage.dart';
import 'package:cloud_app/HomePage/myHomePage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: dotenv.get('url'),
    anonKey: dotenv.get('anonKey'),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: UiTheme.light,
      darkTheme: UiTheme.dark,
      themeMode: ThemeMode.system,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;

          if (session == null) {
            return const LogInPage();
          }

          return MyHomePage();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
