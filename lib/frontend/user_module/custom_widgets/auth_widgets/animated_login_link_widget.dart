import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SignInLoginLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;

  const SignInLoginLink({
    super.key,
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            TextSpan(text: text, style: const TextStyle(color: Colors.black54)),
            TextSpan(
              text: linkText,
              style: const TextStyle(color: Color(0xFF417FB1), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}