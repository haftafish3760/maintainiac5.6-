import 'package:flutter/material.dart';

class EmojiIcon extends StatelessWidget {
  const EmojiIcon(this.emoji, {this.size = 28, super.key});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        height: 1,
        shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
      ),
    );
  }
}
