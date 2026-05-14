import 'package:flutter/material.dart';

class ReviewPhoto {
  const ReviewPhoto({required this.url});

  final String url;
}

class ReviewTag {
  const ReviewTag({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
