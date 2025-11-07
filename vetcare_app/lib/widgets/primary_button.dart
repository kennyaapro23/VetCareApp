import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        minimumSize: const Size.fromHeight(48),
      ),
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    );
  }
}

