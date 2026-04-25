import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../domain/entities/faq/faq.dart';

class FaqItem extends StatefulWidget {
  final Faq faq;
  final bool isFirst;

  const FaqItem({
    super.key,
    required this.faq,
    this.isFirst = false,
  });

  @override
  State<FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<FaqItem> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Expand first item by default
    _isExpanded = widget.isFirst;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.spacing(context, 12),
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5F2D82),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.remove : Icons.add,
                    color: const Color(0xFF5F2D82),
                    size: ResponsiveUtils.fontSize(context, 20),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.only(
                left: ResponsiveUtils.spacing(context, 16),
                right: ResponsiveUtils.spacing(context, 16),
                bottom: ResponsiveUtils.spacing(context, 16),
              ),
              child: Text(
                widget.faq.answer,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
