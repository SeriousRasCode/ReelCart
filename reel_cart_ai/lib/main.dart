import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';

// ----------------------------------------------------
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

// Defines a single shoppable video item (updated with engagement state)
class VideoItem {
  final String id;
  final String title;
  final String creator;
  final String videoUrl; // Mocked for this MVP
  final List<Product> shoppableProducts;
  final Color mockColor; // For visual difference in the feed

  // State for functionality
  bool isLiked;
  int likeCount;

  VideoItem({
    required this.id,
    required this.title,
    required this.creator,
    required this.videoUrl,
    required this.shoppableProducts,
    required this.mockColor,
    this.isLiked = false,
    this.likeCount = 0,
  });
}

// ----------------------------------------------------
// 2. DATA SERVICE (MOCK AI RECOMMENDATION ENGINE)
// ----------------------------------------------------

// Utility to generate random colors for mock videos
final _random = Random();
Color _getRandomColor() => Color.fromRGBO(
  _random.nextInt(256),
  _random.nextInt(256),
  _random.nextInt(256),
  1,
);

// Mock product data
final List<Product> mockProducts = [
  // FIX: Explicitly request PNG format by adding '/png' to the URL path
  Product(
    id: 'p1',
    name: 'Vintage Camera',
    price: 299.99,
    imageUrl: 'https://placehold.co/100x100/png/007bff/ffffff?text=Camera',
  ),
  Product(
    id: 'p2',
    name: 'Leather Satchel',
    price: 145.00,
    imageUrl: 'https://placehold.co/100x100/png/dc3545/ffffff?text=Satchel',
  ),
  Product(
    id: 'p3',
    name: 'Noise Cancelling Headphones',
    price: 350.50,
    imageUrl: 'https://placehold.co/100x100/png/28a745/ffffff?text=Headphones',
  ),
  Product(
    id: 'p4',
    name: 'Minimalist Watch',
    price: 89.99,
    imageUrl: 'https://placehold.co/100x100/png/ffc107/343a40?text=Watch',
  ),
];

// Mock video data generation
List<VideoItem> generateMockVideos(int count, int startingIndex) {
  return List<VideoItem>.generate(count, (index) {
    // Select 1-2 random products for shopping tags
    final products =
        (_random.nextBool() ? mockProducts.take(1) : mockProducts.take(2))
            .toList();

    return VideoItem(
      id: 'v${startingIndex + index + 1}',
      title: 'AI Recommendation Reel #${startingIndex + index + 1}',
      creator: 'Creator_${startingIndex + index + 1}',
      videoUrl: 'mock_video_url_${startingIndex + index + 1}',
      shoppableProducts: products,
      mockColor: _getRandomColor(),
      // Simulate initial engagement data
      likeCount: 500 + _random.nextInt(2000),
      isLiked: _random.nextBool(),
    );
  });
}

// ----------------------------------------------------
// 3. GETX CONTROLLERS
// ----------------------------------------------------

/// Controller for the state of a single video reel (playback and engagement).
class ReelController extends GetxController {
  final VideoItem video;

  // Simulated Video Player State
  final isPlaying = true.obs;

  // Engagement State
  final isLiked = false.obs;
  final likeCount = 0.obs;

  ReelController(this.video) {
    // Initialize observable states from the model data
    likeCount.value = video.likeCount;
    isLiked.value = video.isLiked;

    // In a real app, you would initialize and start the video player here.
    // E.g., _videoPlayerController = VideoPlayerController.network(video.videoUrl);
    // _videoPlayerController.initialize().then((_) => isPlaying.value = true);
  }

  void togglePlayPause() {
    isPlaying.toggle();
    // In a real app: isPlaying.value ? _videoPlayerController.play() : _videoPlayerController.pause();
    Get.snackbar(
      'Playback Status',
      isPlaying.value ? 'Video is playing.' : 'Video is paused.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(milliseconds: 800),
      backgroundColor: Colors.white.withOpacity(0.9),
      colorText: Colors.black,
    );
  }

  void toggleLike() {
    isLiked.toggle();
    if (isLiked.value) {
      likeCount.value++;
    } else {
      likeCount.value--;
    }
    // Update the underlying model state (simulating API call)
    video.likeCount = likeCount.value;
    video.isLiked = isLiked.value;
  }
}

/// Controller for managing the entire endless video feed.
class VideoFeedController extends GetxController {
  // The endless feed of shoppable videos
  final videos = <VideoItem>[].obs;

  // State to handle the visibility of the shoppable product tags overlay
  final isProductOverlayVisible = false.obs;

  // The index of the video currently being viewed
  int currentVideoIndex = 0;

  // Reference to the currently active ReelController
  ReelController? activeReelController;

  @override
  void onInit() {
    loadInitialFeed();
    super.onInit();
  }

  // Simulates loading the initial personalized feed
  void loadInitialFeed() {
    videos.assignAll(generateMockVideos(5, 0));
    Get.snackbar(
      'Feed Ready',
      '5 personalized videos loaded.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Simulates the AI Recommendation Engine loading more content
  void loadMoreVideos() async {
    if (videos.length > 20) return;

    await 2.seconds.delay();

    final newVideos = generateMockVideos(5, videos.length);
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
    // 1. Reset state of old video and update index
    activeReelController?.isPlaying.value = false; // Pause the previous video
    currentVideoIndex = index;
    isProductOverlayVisible.value = false;

    // 2. Load the controller for the new video and start it
    // We fetch the new controller using its tag (the video ID)
    final newController = Get.find<ReelController>(tag: videos[index].id);
    newController.isPlaying.value = true; // Auto-play new video
    activeReelController = newController;

    // 3. Trigger AI loading for more content when near the end of the current feed
    if (index >= videos.length - 3) {
      loadMoreVideos();
    }
  }

  // Toggles the visibility of the shoppable tags
  void toggleProductOverlay() {
    isProductOverlayVisible.value = !isProductOverlayVisible.value;
  }
}

// ----------------------------------------------------
// 4. VIEWS (UI)
// ----------------------------------------------------

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
                style: const TextStyle(
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
class VideoPlayerWidget extends StatelessWidget {
  final VideoItem video;

  // Use a tag to retrieve the specific controller instance for this video
  final ReelController reelController;

  VideoPlayerWidget({Key? key, required this.video})
    : reelController = Get.put(
        ReelController(video),
        tag: video.id,
      ), // Dependency injection for the reel
      super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using a Stack to layer the video (mock), the overlay, and the controls
    return GestureDetector(
      onTap: Get.find<VideoFeedController>().toggleProductOverlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Simulated Video Player View (Background color as the video screen)
          Container(
            color: video.mockColor,
            child: Center(
              // Obx handles the Play/Pause icon visibility
              child: Obx(
                () => reelController.isPlaying.value
                    ? const SizedBox.shrink() // Video is playing, hide button
                    : GestureDetector(
                        onTap: reelController.togglePlayPause,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // 2. Play/Pause Action overlay
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: reelController.toggleLike, // Double tap to like
              onTap: reelController.togglePlayPause, // Single tap to play/pause
              child: const SizedBox.expand(),
            ),
          ),

          // 3. Video Metadata (Bottom Left)
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

          // 4. Right-side Action Buttons (Engagement and Seller actions)
          Positioned(
            bottom: 20,
            right: 10,
            child: Obx(
              () => Column(
                children: [
                  // Shoppable Tag/Product Icon
                  InkWell(
                    onTap: Get.find<VideoFeedController>().toggleProductOverlay,
                    child: const Column(
                      children: [
                        Icon(
                          Icons.local_offer,
                          color: Colors.pinkAccent,
                          size: 30,
                        ),
                        Text(
                          'Tags',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Functional Like Button
                  InkWell(
                    onTap: reelController.toggleLike,
                    child: Column(
                      children: [
                        Icon(
                          reelController.isLiked.value
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: reelController.isLiked.value
                              ? Colors.red
                              : Colors.white,
                          size: 30,
                        ),
                        Text(
                          '${reelController.likeCount.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Share Button
                  const Icon(Icons.share, color: Colors.white, size: 30),
                  const Text(
                    '45',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // 5. Shoppable Tags Overlay
          ShoppableOverlay(video: video),

          // 6. Loading Indicator (When AI is fetching more reels)
          GetX<VideoFeedController>(
            builder: (controller) {
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
                  left: 0,
                  right: 0,
                  child: Center(
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
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
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
        // which represents the endless feed.
        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: controller.videos.length,
          onPageChanged: (index) {
            controller.onVideoPageChanged(index);
          },
          itemBuilder: (context, index) {
            final video = controller.videos[index];
            // Each video now creates and manages its own ReelController instance
            return VideoPlayerWidget(video: video);
          },
        );
      }),
    );
  }
}

// ----------------------------------------------------
// 5. BINDINGS
// ----------------------------------------------------

// Initializes the controller when the app starts
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoFeedController>(() => VideoFeedController());
  }
}

// ----------------------------------------------------
// 6. MAIN APP SETUP
// ----------------------------------------------------

void main() {
  runApp(const ReelCartApp());
}

class ReelCartApp extends StatelessWidget {
  const ReelCartApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ReelCart AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.black, // Dark background for video feed
      ),
      initialBinding: AppBinding(),
      home: const VideoFeedView(),
    );
  }
}
