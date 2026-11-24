import 'package:flutter/material.dart';

/// Reusable primary button with an optional loading state.
///
/// When [isLoading] is true, the button is disabled and shows a circular
/// progress indicator instead of the [text].
class CustomButton extends StatelessWidget {
  /// Label displayed on the button.
  final String text;

  /// Callback invoked when the button is pressed (ignored while loading).
  final VoidCallback? onPressed;

  /// Whether the button is currently in a loading state.
  final bool isLoading;

  /// Creates a [CustomButton] with the given [text] and optional callbacks.
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.indigo.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}