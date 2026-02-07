import 'package:cloud_app/Screens/Home/Widgets/home_shared_ui.dart';
import 'package:flutter/material.dart';

class WebWidgetBody extends StatelessWidget {
  const WebWidgetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeSharedUI(isMobile: false);
  }
}
