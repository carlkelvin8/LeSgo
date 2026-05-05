import 'package:flutter/material.dart';

/// Password strength levels
enum PasswordStrength {
  weak(0.33, Colors.red, 'Weak'),
  medium(0.66, Colors.orange, 'Medium'),
  strong(1.0, Colors.green, 'Strong');

  final double value;
  final Color color;
  final String label;

  const PasswordStrength(this.value, this.color, this.label);
}

/// Widget that displays password strength indicator
/// Shows a progress bar and helpful hints for improving password
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showHints;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showHints = true,
  });

  /// Calculate password strength based on various criteria
  PasswordStrength _calculateStrength() {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;

    // Length criteria
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character type criteria
    if (password.contains(RegExp(r'[A-Z]'))) score++; // Uppercase
    if (password.contains(RegExp(r'[a-z]'))) score++; // Lowercase
    if (password.contains(RegExp(r'[0-9]'))) score++; // Number
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++; // Special char

    // Determine strength based on score
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Get list of missing requirements
  String _getPasswordRequirements() {
    final missing = <String>[];

    if (password.length < 8) missing.add('8+ characters');
    if (!password.contains(RegExp(r'[A-Z]'))) missing.add('uppercase letter');
    if (!password.contains(RegExp(r'[a-z]'))) missing.add('lowercase letter');
    if (!password.contains(RegExp(r'[0-9]'))) missing.add('number');
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      missing.add('special character');
    }

    if (missing.isEmpty) return '';
    return 'Add: ${missing.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if password is empty
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _calculateStrength();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: strength.value,
            backgroundColor: Colors.grey.shade200,
            color: strength.color,
            minHeight: 4,
          ),
        ),
        
        const SizedBox(height: 6),
        
        // Strength label
        Row(
          children: [
            Icon(
              _getStrengthIcon(strength),
              size: 14,
              color: strength.color,
            ),
            const SizedBox(width: 4),
            Text(
              'Password strength: ${strength.label}',
              style: TextStyle(
                fontSize: 12,
                color: strength.color,
                fontWeight: FontWeight.w600,
                fontFamily: 'TT Fors',
              ),
            ),
          ],
        ),
        
        // Hints for improvement
        if (showHints && strength != PasswordStrength.strong) ...[
          const SizedBox(height: 4),
          Text(
            _getPasswordRequirements(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontFamily: 'TT Fors',
            ),
          ),
        ],
      ],
    );
  }

  /// Get icon based on strength
  IconData _getStrengthIcon(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Icons.error_outline;
      case PasswordStrength.medium:
        return Icons.warning_amber_outlined;
      case PasswordStrength.strong:
        return Icons.check_circle_outline;
    }
  }
}
