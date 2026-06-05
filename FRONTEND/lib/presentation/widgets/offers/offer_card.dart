import 'package:flutter/material.dart';

import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/offers/offers_provider.dart';

class OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback onSavePressed;
  final VoidCallback onClaimPressed;

  const OfferCard({
    super.key,
    required this.offer,
    required this.onSavePressed,
    required this.onClaimPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Color(offer.accentColor);

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_serviceIcon(offer.service), color: accent),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            offer.service,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (offer.isFeatured) ...[
                          const SizedBox(width: 8),
                          _MiniBadge(label: 'Featured', color: accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.title,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 17),
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSavePressed,
                icon: Icon(
                  offer.isSaved ? Icons.bookmark : Icons.bookmark_border,
                ),
                color: accent,
                tooltip: offer.isSaved ? 'Saved' : 'Save',
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Text(
            offer.description,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              color: Colors.grey[600],
              height: 1.35,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 14)),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        color: accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          offer.code,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  offer.discountLabel,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 14)),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Valid until ${offer.expiresAt}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey[500],
                  ),
                ),
              ),
              TextButton(
                onPressed: (offer.isClaimed || !offer.isEligible)
                    ? null
                    : onClaimPressed,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  offer.isClaimed
                      ? 'Claimed'
                      : (!offer.isEligible ? 'Not eligible' : 'Claim'),
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _serviceIcon(String service) {
    switch (service) {
      case 'LesRide':
        return Icons.two_wheeler;
      case 'LesEat':
        return Icons.restaurant;
      case 'LesPay':
        return Icons.account_balance_wallet;
      case 'LesBuy':
        return Icons.shopping_bag;
      default:
        return Icons.local_shipping;
    }
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 10),
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
