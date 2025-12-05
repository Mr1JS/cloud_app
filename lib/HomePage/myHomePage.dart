import 'package:cloud_app/HomePage/components/storageBarDelegate.dart';
import 'package:flutter/material.dart';
import 'package:cloud_app/LoginSignupPage/LoginSignupCom/LoginPage.dart';
import 'package:cloud_app/auth_service.dart';

class MyHomePage extends StatelessWidget {
  final _auth = AuthService();

  late final user = (_auth.getUserEmail()!).split('@')[0];

  MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Text("User: $user"),
            actions: [
              IconButton(
                onPressed: () {
                  _auth.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LogInPage()),
                  );
                },
                icon: Icon(Icons.logout),
              ),
            ],
            centerTitle: true,
            expandedHeight: 200,
            pinned: true,
          ),

          SliverPersistentHeader(delegate: Storagebardelegate(), pinned: true),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
