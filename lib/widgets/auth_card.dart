import 'package:flutter/material.dart';

class AuthCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool showLogo;

  const AuthCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.children,
    this.showLogo = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLogo)
              Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))],
                    ),
                    child: Center(
                      child: Text(
                        'MV',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
            ],

            const SizedBox(height: 18),

            ...children,
          ],
        ),
      ),
    );
  }
}
