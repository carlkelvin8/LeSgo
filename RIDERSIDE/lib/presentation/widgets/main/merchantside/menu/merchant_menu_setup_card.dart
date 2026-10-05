import 'package:flutter/material.dart';

// ─── Empty category banner ────────────────────────────────────────────────────
class MerchantMenuSetupCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAction;
  final String actionLabel;
  const MerchantMenuSetupCard({
    super.key,
    required this.isDark,
    required this.onAction,
    this.actionLabel = 'Set up menu',
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D36C8);
    final ink = isDark ? Colors.white : const Color(0xFF251A38);
    final muted = isDark ? const Color(0xFFC0B2D2) : const Color(0xFF71647F);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF211B2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF432B60) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 28,
              color: isDark ? const Color(0xFFC8A5FF) : purple,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Your menu starts here',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create your first category, then add the dishes your customers will love.',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 14,
              height: 1.6,
              color: muted,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Meals', 'Drinks', 'Desserts']
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF352741) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF49335F)
                            : const Color(0xFFE8DCF5),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(actionLabel, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
