import 'package:flutter/material.dart';

class ReaderStyleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReaderStyleButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.text_fields),
      tooltip: 'Reading Settings',
      onPressed: onPressed,
    );
  }
}