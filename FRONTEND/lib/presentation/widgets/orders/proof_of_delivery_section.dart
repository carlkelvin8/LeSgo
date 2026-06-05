import 'package:flutter/material.dart';

import '../../../core/utils/proof_image_utils.dart';
import '../../../core/utils/responsive_utils.dart';

class ProofOfDeliverySection extends StatelessWidget {
  final List<String> imageUrls;

  const ProofOfDeliverySection({
    super.key,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_outlined, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Proof of Delivery',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              final imageUrl = imageUrls[index];
              return GestureDetector(
                onTap: () => _openPreview(context, imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _ProofNetworkImage(url: imageUrl),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: InteractiveViewer(
          child: _ProofNetworkImage(url: imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _ProofNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const _ProofNetworkImage({
    required this.url,
    this.fit = BoxFit.cover,
  });

  @override
  State<_ProofNetworkImage> createState() => _ProofNetworkImageState();
}

class _ProofNetworkImageState extends State<_ProofNetworkImage> {
  late String _currentUrl;
  String? _fallbackUrl;
  bool _triedFallback = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _fallbackUrl = ProofImageUtils.alternateProofUrl(widget.url);
  }

  @override
  void didUpdateWidget(covariant _ProofNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _currentUrl = widget.url;
      _fallbackUrl = ProofImageUtils.alternateProofUrl(widget.url);
      _triedFallback = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _currentUrl,
      fit: widget.fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        if (!_triedFallback &&
            _fallbackUrl != null &&
            _fallbackUrl != _currentUrl) {
          _triedFallback = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _currentUrl = _fallbackUrl!);
            }
          });
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
}
