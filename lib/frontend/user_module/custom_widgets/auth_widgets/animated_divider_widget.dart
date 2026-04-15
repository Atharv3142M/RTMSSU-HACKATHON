import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SignInDivider extends StatelessWidget {
  final String label;

  const SignInDivider({super.key, this.label = 'or'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1.2)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const Expanded(child: Divider(thickness: 1.2)),
      ],
    );
  }
}
