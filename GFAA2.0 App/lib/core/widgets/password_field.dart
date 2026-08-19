import 'package:flutter/material.dart';

/// A password `TextFormField` with a show/hide toggle — used everywhere a
/// password is entered (login, register, reset, practitioner application)
/// so the behavior stays identical across the app.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.decorationBuilder,
  });

  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;

  /// Lets a screen apply its own field styling (e.g. the auth screens'
  /// pill-shaped fields with a leading icon) while still getting the
  /// show/hide toggle wired in automatically — called with the base
  /// decoration this widget would otherwise use.
  final InputDecoration Function(InputDecoration base)? decorationBuilder;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final toggle = IconButton(
      icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      tooltip: _obscured ? 'Show password' : 'Hide password',
      onPressed: () => setState(() => _obscured = !_obscured),
    );
    final baseDecoration = InputDecoration(labelText: widget.labelText, suffixIcon: toggle);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      decoration: widget.decorationBuilder?.call(baseDecoration) ?? baseDecoration,
      validator: widget.validator,
    );
  }
}
