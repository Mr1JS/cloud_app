import 'package:flutter/material.dart';

/// -----------------------------
/// Searchbar Controller
/// -----------------------------
class Searchbar {
  final SearchController searchController = SearchController();
  final VoidCallback onUpdate;

  Searchbar({required this.onUpdate}) {
    searchController.addListener(() {
      onUpdate();
    });
  }

  void clear() => searchController.clear();
  String get query => searchController.text;
  void dispose() => searchController.dispose();
}
