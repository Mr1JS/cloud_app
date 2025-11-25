import 'package:flutter/material.dart';
import 'package:cloud_app/LoginSignupCom/LoginPage.dart';
import 'package:cloud_app/myHomePage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(
        body: Supabase.instance.client.auth.currentSession != null
            ? MyHomePage()
            : LogInPage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
