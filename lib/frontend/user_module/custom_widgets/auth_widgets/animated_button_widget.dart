import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedSignInButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  const AnimatedSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.login,
  });

  @override
  State<AnimatedSignInButton> createState() => _AnimatedSignInButtonState();
}

class _AnimatedSignInButtonState extends State<AnimatedSignInButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.1,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? ((_) => _controller.forward()) : null,
      onTapUp: widget.onPressed != null ? ((_) => _controller.reverse()) : null,
      onTapCancel: widget.onPressed != null ? (() => _controller.reverse()) : null,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
