import 'package:flutter/material.dart';

class InboxSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const InboxSearchField({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search in messages',
          hintStyle: TextStyle(
            fontFamily: 'TT Fors',
            color: Colors.grey[500],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
