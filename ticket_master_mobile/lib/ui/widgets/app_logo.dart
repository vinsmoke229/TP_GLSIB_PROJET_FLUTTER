import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showSubtitle = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/ticket_master_logo.png',
      width: size * 2,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        
        return Icon(Icons.error, size: size, color: Colors.red);
      },
    );
  }
}

class AppLogoCompact extends StatelessWidget {
  const AppLogoCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/ticket_master_logo.png',
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.confirmation_number_rounded, size: 40);
      },
    );
  }
}
