import 'package:flutter/material.dart';

const Map<String, IconData> kCategoryIcons = {
  'payments': Icons.payments_rounded,
  'storefront': Icons.storefront_rounded,
  'trending_up': Icons.trending_up_rounded,
  'card_giftcard': Icons.card_giftcard_rounded,
  'restaurant': Icons.restaurant_rounded,
  'directions_car': Icons.directions_car_rounded,
  'receipt_long': Icons.receipt_long_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'medical_services': Icons.medical_services_rounded,
  'movie': Icons.movie_rounded,
  'school': Icons.school_rounded,
  'category': Icons.category_rounded,
  'more_horiz': Icons.more_horiz_rounded,
};

IconData iconFor(String name) => kCategoryIcons[name] ?? Icons.category_rounded;
