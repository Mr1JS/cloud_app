import 'package:cloud_app/HomePage/components/avatarWidget.dart';
import 'package:flutter/material.dart';

class ProfileDialog extends StatelessWidget {
  final String username;
  final String email;
  final String? imageUrl;
  final VoidCallback onEditImage;

  const ProfileDialog({
    super.key,
    required this.username,
    required this.email,
    required this.imageUrl,
    required this.onEditImage,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(
        child: Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarWidget(
            imageUrl: imageUrl,
            username: username,
            radius: 40,
            onEdit: onEditImage,
          ),
          const SizedBox(height: 12),
          Text('Username: $username', overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('Email: $email', overflow: TextOverflow.ellipsis),
          const SizedBox(height: 25),
          Text(
            '© 2025 Cloud App.\n All rights reserved.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
