import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';

// 1. MODELS
// ----------------------------------------------------

// Defines a single product that can be tagged in a video
class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });
}

// Defines a single shoppable video item
class VideoItem {
  final String id;
  final String title;
  final String creator;
  final String videoUrl; // Mocked for this MVP
  final List<Product> shoppableProducts;
  final Color mockColor; // For visual difference in the feed

  VideoItem({
    required this.id,
    required this.title,
    required this.creator,
    required this.videoUrl,
    required this.shoppableProducts,
    required this.mockColor,
  });
}
