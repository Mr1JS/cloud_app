import 'package:cloud_app/Screens/Home/Widgets/home_shared_ui.dart';
import 'package:flutter/material.dart';

class MobileWidgetBody extends StatelessWidget {
  const MobileWidgetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeSharedUI(isMobile: true);
  }
}
