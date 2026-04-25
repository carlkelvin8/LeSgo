import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/snackbar_utils.dart';
import '../../../widgets.dart';

class ManualOrderFormSection extends StatefulWidget {
  final Function(String name, String description, int quantity) onAddItem;

  const ManualOrderFormSection({super.key, required this.onAddItem});

  @override
  State<ManualOrderFormSection> createState() => _ManualOrderFormSectionState();
}

class _ManualOrderFormSectionState extends State<ManualOrderFormSection> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleAddItem() {
    if (_nameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter an item name');
      return;
    }

    widget.onAddItem(
      _nameController.text,
      _descriptionController.text,
      _quantity,
    );

    // Clear form
    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _quantity = 1;
    });

    // Show success message
    SnackBarUtils.showSuccess(context, 'Item added to list');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Add New Item',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 16)),

          // Item Name / Description Field
          CustomTextField(
            controller: _nameController,
            labelText: 'Item Name / Description',
            keyboardType: TextInputType.text,
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 16)),

          // Quantity Section
          Text(
            'Quantity',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 8)),

          // Quantity Controls
          Row(
            children: [
              // Decrement Button
              InkWell(
                onTap: () {
                  if (_quantity > 1) {
                    setState(() {
                      _quantity--;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
              ),

              // Quantity Display
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    _quantity.toString(),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              // Increment Button
              InkWell(
                onTap: () {
                  setState(() {
                    _quantity++;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F2D82),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),

              SizedBox(width: ResponsiveUtils.spacing(context, 12)),

              // Add to List Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _handleAddItem,
                  icon: const Icon(Icons.playlist_add, size: 20),
                  label: Text(
                    'Add to List',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.spacing(context, 12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
