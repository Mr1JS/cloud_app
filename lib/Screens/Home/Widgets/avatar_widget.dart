import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String username;
  final double radius;
  final VoidCallback? onEdit;

  const AvatarWidget({
    super.key,
    required this.imageUrl,
    required this.username,
    required this.radius,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.lightBlue,
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: radius,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (onEdit != null)
          CircleAvatar(
            radius: 14,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
      ],
    );
  }
}
