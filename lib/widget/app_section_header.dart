import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final ImageProvider avatarProvider;
  final VoidCallback onTapProfile;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;
  final bool showAvatar;

  const AppSectionHeader({
    required this.title,
    required this.avatarProvider,
    required this.onTapProfile,
    this.padding = const EdgeInsets.fromLTRB(14, 10, 14, 14),
    this.trailing,
    this.showAvatar = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      child: Row(
        children: [
          if (showAvatar)
            InkWell(
              onTap: onTapProfile,
              borderRadius: BorderRadius.circular(16),
              child: CircleAvatar(radius: 13, backgroundImage: avatarProvider),
            )
          else
            const SizedBox(width: 26, height: 26),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 26),
        ],
      ),
    );
  }
}
