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

// 3. GETX CONTROLLER

class VideoFeedController extends GetxController {
  // The endless feed of shoppable videos
  final videos = <VideoItem>[].obs;

  // State to handle the visibility of the shoppable product tags overlay
  final isProductOverlayVisible = false.obs;

  // The index of the video currently being viewed
  int currentVideoIndex = 0;

  @override
  void onInit() {
    // 1. Initial Load: Load the first set of recommended videos
    loadInitialFeed();
    super.onInit();
  }

  // Simulates loading the initial personalized feed
  void loadInitialFeed() {
    videos.assignAll(generateMockVideos(5));
    Get.snackbar(
      'Feed Ready',
      '5 personalized videos loaded.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Simulates the AI Recommendation Engine loading more content
  void loadMoreVideos() async {
    // Prevent multiple simultaneous loads
    if (videos.length > 20) return; // Simple safety limit for MVP

    // Simulate network delay
    await 2.seconds.delay();

    // The core AI logic simulation: Append a new batch of 5 videos
    final newVideos = generateMockVideos(5);
    videos.addAll(newVideos);

    Get.snackbar(
      'AI Recommendation',
      'New batch of ${newVideos.length} videos added to the end of the feed.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  // Handles the vertical scroll event (user viewing a new video)
  void onVideoPageChanged(int index) {
    currentVideoIndex = index;
    // Hide overlay when video changes
    isProductOverlayVisible.value = false;

    // Trigger AI loading for more content when near the end of the current feed

    if (index >= videos.length - 3) {
      loadMoreVideos();
    }
  }

  // Toggles the visibility of the shoppable tags
  void toggleProductOverlay() {
    isProductOverlayVisible.value = !isProductOverlayVisible.value;
  }
}

// 4. VIEWS (UI)

// Product card shown in the overlay
class ProductTag extends StatelessWidget {
  final Product product;

  const ProductTag({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(product.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              size: 20,
              color: Colors.pink,
            ),
            onPressed: () {
              // Action: Buy instantly without leaving the video
              Get.snackbar(
                'Purchased!',
                '${product.name} added to cart instantly.',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.pinkAccent,
                colorText: Colors.white,
              );
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
