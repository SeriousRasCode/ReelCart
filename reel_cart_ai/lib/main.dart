import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';

// 1. MODELS

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
  final String videoUrl;
  final List<Product> shoppableProducts;
  final Color mockColor;

  VideoItem({
    required this.id,
    required this.title,
    required this.creator,
    required this.videoUrl,
    required this.shoppableProducts,
    required this.mockColor,
  });
}

// 2. DATA SERVICE

final _random = Random();
Color _getRandomColor() => Color.fromRGBO(
  _random.nextInt(256),
  _random.nextInt(256),
  _random.nextInt(256),
  1,
);

// Mock product data
final List<Product> mockProducts = [
  Product(
    id: 'p1',
    name: 'Vintage Camera',
    price: 299.99,
    imageUrl: 'https://placehold.co/100x100/007bff/ffffff?text=Camera',
  ),
  Product(
    id: 'p2',
    name: 'Leather Satchel',
    price: 145.00,
    imageUrl: 'https://placehold.co/100x100/dc3545/ffffff?text=Satchel',
  ),
  Product(
    id: 'p3',
    name: 'Noise Cancelling Headphones',
    price: 350.50,
    imageUrl: 'https://placehold.co/100x100/28a745/ffffff?text=Headphones',
  ),
  Product(
    id: 'p4',
    name: 'Minimalist Watch',
    price: 89.99,
    imageUrl: 'https://placehold.co/100x100/ffc107/343a40?text=Watch',
  ),
];

// Mock video data generation
List<VideoItem> generateMockVideos(int count) {
  return List<VideoItem>.generate(count, (index) {
    // Select 1-2 random products for shopping tags
    final products =
        (_random.nextBool() ? mockProducts.take(1) : mockProducts.take(2))
            .toList();

    return VideoItem(
      id: 'v${index + 1}',
      title: 'Aesthetic shot #${index + 1}',
      creator: 'ReelCartCreator${index + 1}',
      videoUrl: 'mock_video_url_${index + 1}',
      shoppableProducts: products,
      mockColor: _getRandomColor(),
    );
  });
}
