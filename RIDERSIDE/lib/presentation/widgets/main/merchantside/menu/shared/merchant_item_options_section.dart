import 'package:flutter/material.dart';
import '../../../../../../core/utils/menu_item_options.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantItemOptionsSection extends StatelessWidget {
  final MenuItemOptionGroups optionGroups;
  final ValueChanged<MenuItemOptionGroups> onChanged;

  const MerchantItemOptionsSection({
    super.key,
    required this.optionGroups,
    required this.onChanged,
  });

  void _update({
    List<MenuOptionChoice>? sizes,
    List<MenuOptionChoice>? flavors,
    List<MenuOptionChoice>? addons,
  }) {
    onChanged(
      MenuItemOptionGroups(
        sizes: sizes ?? optionGroups.sizes,
        flavors: flavors ?? optionGroups.flavors,
        addons: addons ?? optionGroups.addons,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sizes, Flavors & Add-ons',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Text(
          'Let customers pick size, flavor, and add-ons when ordering.',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        _OptionEditor(
          title: 'Sizes',
          choices: optionGroups.sizes,
          onChanged: (choices) => _update(sizes: choices),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _OptionEditor(
          title: 'Flavors',
          choices: optionGroups.flavors,
          onChanged: (choices) => _update(flavors: choices),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _OptionEditor(
          title: 'Add-ons',
          choices: optionGroups.addons,
          onChanged: (choices) => _update(addons: choices),
        ),
      ],
    );
  }
}

class _OptionEditor extends StatefulWidget {
  final String title;
  final List<MenuOptionChoice> choices;
  final ValueChanged<List<MenuOptionChoice>> onChanged;

  const _OptionEditor({
    required this.title,
    required this.choices,
    required this.onChanged,
  });

  @override
  State<_OptionEditor> createState() => _OptionEditorState();
}

class _OptionEditorState extends State<_OptionEditor> {
  late List<_OptionEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.choices
        .map((choice) => _OptionEntry(label: choice.label, price: choice.price))
        .toList();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final choices = _entries
        .where((entry) => entry.label.trim().isNotEmpty)
        .map(
          (entry) => MenuOptionChoice(
            label: entry.label.trim(),
            price: double.tryParse(entry.price.replaceAll(',', '')) ?? 0,
          ),
        )
        .toList();
    widget.onChanged(choices);
  }

  void _addEntry() {
    setState(() {
      _entries.add(_OptionEntry());
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
      _emit();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Add ${widget.title.substring(0, widget.title.length - 1)}',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                ),
              ),
            ),
          ],
        ),
        if (_entries.isEmpty)
          Text(
            'No ${widget.title.toLowerCase()} yet',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: Colors.grey.shade500,
            ),
          ),
        ...List.generate(_entries.length, (index) {
          final entry = _entries[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtils.spacing(context, 8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: entry.labelController,
                    onChanged: (_) => _emit(),
                    onEditingComplete: _emit,
                    decoration: InputDecoration(
                      hintText: 'Name',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.spacing(context, 10),
                        vertical: ResponsiveUtils.spacing(context, 8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: entry.priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _emit(),
                    onEditingComplete: _emit,
                    decoration: InputDecoration(
                      hintText: 'Extra ₱',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.spacing(context, 10),
                        vertical: ResponsiveUtils.spacing(context, 8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeEntry(index),
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.red.shade400,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _OptionEntry {
  final TextEditingController labelController;
  final TextEditingController priceController;

  _OptionEntry({String label = '', double price = 0})
      : labelController = TextEditingController(text: label),
        priceController = TextEditingController(
          text: price > 0 ? price.toStringAsFixed(0) : '',
        );

  String get label => labelController.text;
  String get price => priceController.text;

  void dispose() {
    labelController.dispose();
    priceController.dispose();
  }
}
