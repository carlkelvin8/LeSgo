import 'package:flutter/material.dart';

class LeseatControllers {
  final TextEditingController searchController;

  LeseatControllers() : searchController = TextEditingController();

  void dispose() {
    searchController.dispose();
  }

  void clearSearch() {
    searchController.clear();
  }
}
