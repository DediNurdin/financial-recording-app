import 'package:flutter/material.dart';

import '../utils/category_style.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.icon,
    required this.color,
    this.radius = 20,
  });

  final String icon;
  final int color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.withValues(alpha: 0.15),
      child: Icon(iconFor(icon), color: c, size: radius),
    );
  }
}
