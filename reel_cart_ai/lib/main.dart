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

// Overlay to display all shoppable products for the current video
class ShoppableOverlay extends GetView<VideoFeedController> {
  final VideoItem video;

  const ShoppableOverlay({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60, // Above the controls
      left: 10,
      right: 10,
      child: Obx(() {
        if (!controller.isProductOverlayVisible.value) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // List of product tags
            ...video.shoppableProducts
                .map((p) => ProductTag(product: p))
                .toList(),

            const SizedBox(height: 16),

            // Interaction hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Tap anywhere to close tags',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// Single Video Player (The core Reel)
class VideoPlayerWidget extends GetView<VideoFeedController> {
  final VideoItem video;

  const VideoPlayerWidget({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using a Stack to layer the video (mock), the overlay, and the controls
    return GestureDetector(
      onTap: controller.toggleProductOverlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Mock Video Player (Placeholder background)
          Container(
            color: video.mockColor,
            child: const Center(
              child: Icon(Icons.play_arrow, size: 80, color: Colors.white54),
            ),
          ),

          // 2. Video Metadata (Bottom Left)
          Positioned(
            bottom: 20,
            left: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${video.creator}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: Get.width * 0.7,
                  child: Text(
                    video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 3. Right-side Action Buttons (Simulated engagement/seller actions)
          Positioned(
            bottom: 20,
            right: 10,
            child: Column(
              children: [
                // Shoppable Tag/Product Icon
                const Icon(
                  Icons.local_offer,
                  color: Colors.pinkAccent,
                  size: 30,
                ),
                Text(
                  '${video.shoppableProducts.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Like Button
                const Icon(Icons.favorite, color: Colors.white, size: 30),
                const Text('1.2K', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 20),

                // Share Button
                const Icon(Icons.share, color: Colors.white, size: 30),
                const Text('45', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),

          // 4. Shoppable Tags Overlay
          ShoppableOverlay(video: video),

          // 5. Loading Indicator (When AI is fetching more reels)
          Obx(() {
            if (controller.videos.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            // Check if this is the last or near-last video while loading more
            if (controller.videos.length - 1 <=
                    controller.currentVideoIndex + 1 &&
                controller.videos.length < 20) {
              return Positioned(
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'AI Curating Next Reel...',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

// The main screen with the endless, personalized video feed
class VideoFeedView extends GetView<VideoFeedController> {
  const VideoFeedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'ReelCart AI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            onPressed: () {
              // Simulate Seller Tool: AI product tagging
              Get.snackbar(
                'Seller Tool',
                'Opening AI video tagging tool for sellers...',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        if (controller.videos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Use PageView.builder to handle the vertical scrolling experience
        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: controller.videos.length,
          onPageChanged: controller.onVideoPageChanged,
          itemBuilder: (context, index) {
            final video = controller.videos[index];
            return VideoPlayerWidget(video: video);
          },
        );
      }),
    );
  }
}
