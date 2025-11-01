import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NavIcon extends StatelessWidget {
  final String iconLine;
  final String iconSolid;
  final bool selected;
  final VoidCallback onTap;

  const NavIcon({
    super.key,
    required this.iconLine,
    required this.iconSolid,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = selected ? iconSolid : iconLine;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 160),
        child: SvgPicture.asset(
          icon,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            selected
                ? Colors.black
                : Colors.black.withOpacity(0.45),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
