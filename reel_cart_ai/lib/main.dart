import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';

// --- Global Constants for Mocking Real Assets ---
const String mockVideoThumbnailUrl =
    "https://placehold.co/600x1000/2A2F34/FFFFFF/png?text=AI+Reel+Content";
const String mockCreatorImageUrl =
    "https://placehold.co/40x40/FF69B4/FFFFFF/png?text=P";

// ----------------------------------------------------
// 1. MODELS
// ----------------------------------------------------

// Defines a single product that can be tagged in a video
class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});

  // Method for easy comparison and cart grouping
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Defines an item within the shopping cart
class CartItem {
  final Product product;
  final RxInt quantity;

  CartItem({required this.product, required int initialQuantity})
    : quantity = initialQuantity.obs; // Quantity is observable
}

// Defines a single shoppable video item
class VideoItem {
  final String id;
  final String title;
  final String creator;
  final String videoUrl; // <--- This is the actual video stream URL
  final String
  thumbnailUrl; // <--- This is the image used as the visual placeholder
  final List<Product> shoppableProducts;

  bool isLiked;
  int likeCount;

  VideoItem({
    required this.id,
    required this.title,
    required this.creator,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.shoppableProducts,
    this.isLiked = false,
    this.likeCount = 0,
  });
}

// ----------------------------------------------------
// 2. DATA SERVICE (MOCK AI RECOMMENDATION ENGINE)
// ----------------------------------------------------

final _random = Random();

final List<Product> mockProducts = [
  Product(id: 'p1', name: 'Vintage Camera', price: 299.99),
  Product(id: 'p2', name: 'Leather Satchel', price: 145.00),
  Product(id: 'p3', name: 'Noise Cancelling Headphones', price: 350.50),
  Product(id: 'p4', name: 'Minimalist Watch', price: 89.99),
];

List<VideoItem> generateMockVideos(int count, int startingIndex) {
  return List<VideoItem>.generate(count, (index) {
    final products =
        (_random.nextBool() ? mockProducts.take(1) : mockProducts.take(2))
            .toList();

    return VideoItem(
      id: 'v${startingIndex + index + 1}',
      title:
          'AI Recommendation Reel #${startingIndex + index + 1}: ${products.map((p) => p.name).join(' & ')} Review',
      creator: 'Creator_${startingIndex + index + 1}',
      videoUrl:
          'https://mock-video-stream.com/reel-id-${startingIndex + index + 1}.mp4', // Mock real URL
      thumbnailUrl: mockVideoThumbnailUrl, // Use a consistent mock image
      shoppableProducts: products,
      likeCount: 500 + _random.nextInt(2000),
      isLiked: _random.nextBool(),
    );
  });
}

// ----------------------------------------------------
// 3. GETX CONTROLLERS
// ----------------------------------------------------

/// Controller for global application state (navigation, active page)
class RootController extends GetxController {
  // 0: Feed, 1: Search, 2: Cart, 3: Profile
  final currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
    // When navigating away from the feed, ensure the active video is paused
    if (index != 0) {
      Get.find<FeedController>().activeReelController?.isPlaying.value = false;
    }
    // When navigating back to the feed, ensure the active video starts playing
    if (index == 0) {
      // Small delay to ensure the PageView has settled
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.find<FeedController>().activeReelController?.isPlaying.value = true;
      });
    }
  }
}

/// Controller for managing the shopping cart and its calculations
class CartController extends GetxController {
  final cartItems = <CartItem>[].obs;
  static const double _taxRate = 0.08; // 8% tax

  // Track which product IDs already have quantity listeners registered
  final Set<String> _quantityListenerSetup = <String>{};

  // --- Computed Properties ---
  final subtotal = 0.0.obs;
  final tax = 0.0.obs;
  final total = 0.0.obs;

  @override
  void onInit() {
    // Recompute totals whenever cart items change and ensure quantity listeners are set up
    ever(cartItems, (_) {
      _setupQuantityListeners();
      _updateTotals();
    });
    super.onInit();
  }

  // Helper to ensure all items' quantity changes are tracked (register once per product)
  void _setupQuantityListeners() {
    for (var item in cartItems) {
      // Skip if we've already attached a listener for this product id
      if (_quantityListenerSetup.contains(item.product.id)) continue;

      ever(item.quantity, (_) => _updateTotals());
      _quantityListenerSetup.add(item.product.id);
    }
  }

  void _updateTotals() {
    double newSubtotal = 0.0;
    for (var item in cartItems) {
      newSubtotal += item.product.price * item.quantity.value;
    }
    subtotal.value = newSubtotal;
    tax.value = newSubtotal * _taxRate;
    total.value = newSubtotal + tax.value;
  }

  void addToCart(Product product) {
    final existingItem = cartItems.firstWhereOrNull(
      (item) => item.product.id == product.id,
    );

    if (existingItem != null) {
      existingItem.quantity.value++;
    } else {
      final newItem = CartItem(product: product, initialQuantity: 1);
      cartItems.add(newItem);
    }
    _setupQuantityListeners(); // Ensure listener is attached for new item
    _updateTotals();

    Get.snackbar(
      'Cart Updated',
      '${product.name} added to cart.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
    );
  }

  void incrementQuantity(CartItem item) => item.quantity.value++;

  void decrementQuantity(CartItem item) {
    if (item.quantity.value > 1) {
      item.quantity.value--;
    } else {
      // Remove item if quantity drops to 1 (will be 0 after decrement and removal)
      removeItem(item);
    }
  }

  void removeItem(CartItem item) {
    cartItems.removeWhere((cartItem) => cartItem.product.id == item.product.id);
    // Clean up tracking so listeners won't be re-skipped if the same product is re-added later
    _quantityListenerSetup.remove(item.product.id);
    _updateTotals();
    Get.snackbar(
      'Item Removed',
      '${item.product.name} removed from cart.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
    );
  }

  void clearCart() {
    cartItems.clear();
    _quantityListenerSetup.clear();
    _updateTotals();
  }
}

/// Controller for managing the state of a single video reel
class ReelController extends GetxController {
  final VideoItem video;

  // --- Video Player Mock State ---
  // In a real app, this would be a VideoPlayerController
  final isPlaying = true.obs;

  // --- Engagement State ---
  final isLiked = false.obs;
  final likeCount = 0.obs;

  ReelController(this.video) {
    likeCount.value = video.likeCount;
    isLiked.value = video.isLiked;
  }

  void togglePlayPause() {
    isPlaying.toggle();
    // In a real application, you would use:
    // isPlaying.value ? _videoPlayerController.play() : _videoPlayerController.pause();
  }

  void toggleLike() {
    isLiked.toggle();
    if (isLiked.value) {
      likeCount.value++;
    } else {
      likeCount.value--;
    }
    video.likeCount = likeCount.value;
    video.isLiked = isLiked.value;
  }
}

/// Controller for managing the endless video feed.
class FeedController extends GetxController {
  final videos = <VideoItem>[].obs;
  final isProductOverlayVisible = false.obs;
  int currentVideoIndex = 0;

  ReelController? activeReelController;

  @override
  void onInit() {
    loadInitialFeed();
    super.onInit();
  }

  void loadInitialFeed() {
    videos.assignAll(generateMockVideos(5, 0));
    Get.snackbar(
      'Feed Ready',
      '5 personalized videos loaded.',
      snackPosition: SnackPosition.BOTTOM,
    );
    // Initial controller setup for the first video
    onVideoPageChanged(0);
  }

  void loadMoreVideos() async {
    if (videos.length > 20) return;

    await 2.seconds.delay();

    final newVideos = generateMockVideos(5, videos.length);
    videos.addAll(newVideos);
  }

  void onVideoPageChanged(int index) {
    // Pause previous video, set new index
    activeReelController?.isPlaying.value = false;
    currentVideoIndex = index;
    isProductOverlayVisible.value = false;

    // Only attempt to find the new controller if the index is valid
    if (index < videos.length) {
      // We use Get.put/find with a tag based on the video ID to manage controllers per reel
      final newController = Get.put(
        ReelController(videos[index]),
        tag: videos[index].id,
        permanent: true,
      );

      // Only play the new video if we are on the Feed page
      if (Get.find<RootController>().currentIndex.value == 0) {
        newController.isPlaying.value = true;
      }
      activeReelController = newController;

      // Load more content when near the end
      if (index >= videos.length - 3) {
        loadMoreVideos();
      }
    }
  }

  void toggleProductOverlay() {
    isProductOverlayVisible.value = !isProductOverlayVisible.value;
  }
}

// ----------------------------------------------------
// 4. VIEWS (UI)
// ----------------------------------------------------

// Utility to get a relevant icon for the product tag
IconData _getProductIcon(String productName) {
  if (productName.contains('Camera')) return Icons.camera_alt_outlined;
  if (productName.contains('Satchel')) return Icons.shopping_bag_outlined;
  if (productName.contains('Headphones')) return Icons.headphones_outlined;
  if (productName.contains('Watch')) return Icons.watch_outlined;
  return Icons.shopping_basket_outlined;
}

// Product card shown in the overlay
class ProductTag extends StatelessWidget {
  final Product product;
  final CartController cartController = Get.find<CartController>();

  ProductTag({Key? key, required this.product}) : super(key: key);

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
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getProductIcon(product.name),
              color: Colors.pink,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            // Use Expanded to prevent overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          ),
          IconButton(
            icon: const Icon(
              Icons.add_shopping_cart,
              size: 20,
              color: Colors.pink,
            ),
            onPressed: () {
              cartController.addToCart(product);
              // Navigate to cart page automatically after adding
              Get.find<RootController>().changePage(2);
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// Overlay to display all shoppable products for the current video
class ShoppableOverlay extends GetView<FeedController> {
  final VideoItem video;

  const ShoppableOverlay({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60,
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
            ...video.shoppableProducts
                .map((p) => ProductTag(product: p))
                .toList(),
          ],
        );
      }),
    );
  }
}

// Single Video Player (The core Reel)
class VideoPlayerWidget extends StatelessWidget {
  final VideoItem video;
  final ReelController reelController;

  VideoPlayerWidget({Key? key, required this.video})
    : reelController = Get.find<ReelController>(tag: video.id),
      super(key: key);

  Widget _buildPlaybackIcon(bool isPlaying) {
    return AnimatedOpacity(
      opacity: isPlaying ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: isPlaying,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to isPlaying state only when the Feed tab is active (index 0)
    final isFeedActive = Get.find<RootController>().currentIndex.value == 0;

    return GestureDetector(
      onTap: Get.find<FeedController>().toggleProductOverlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Stream Placeholder View
          Container(
            color: Colors.black, // Background color for video area
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Network Image Placeholder for Video
                Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.pink.shade300,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        "Error: Could not load real video/thumbnail from URL:\n${video.videoUrl}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
                // Dimming overlay for better text contrast
                Container(color: Colors.black.withOpacity(0.35)),
              ],
            ),
          ),

          // 2. Play/Pause Action overlay
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: reelController.toggleLike,
              onTap: reelController.togglePlayPause,
              child: const SizedBox.expand(),
            ),
          ),

          // 3. Play/Pause Icon Center
          Center(
            child: Obx(
              () => _buildPlaybackIcon(
                reelController.isPlaying.value && isFeedActive,
              ),
            ),
          ),

          // 4. Video Metadata (Bottom Left)
          Positioned(
            bottom: 20,
            left: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(
                        mockCreatorImageUrl,
                      ), // Creator profile image
                      backgroundColor: Colors.pinkAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '@${video.creator}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: Get.width * 0.7,
                  child: Text(
                    video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Explicitly show the mock URL to demonstrate the structure
                const SizedBox(height: 4),
                SizedBox(
                  width: Get.width * 0.7,
                  child: Text(
                    'STREAM MOCK: ${video.videoUrl.split('/').last}',
                    style: TextStyle(color: Colors.pink.shade100, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

          // 5. Right-side Action Buttons
          Positioned(
            bottom: 20,
            right: 10,
            child: Obx(
              () => Column(
                children: [
                  // Shoppable Tag Icon
                  InkWell(
                    onTap: Get.find<FeedController>().toggleProductOverlay,
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

          // 6. Shoppable Tags Overlay
          ShoppableOverlay(video: video),
        ],
      ),
    );
  }
}

// The main screen for the video feed (Home tab)
class FeedView extends GetView<FeedController> {
  const FeedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Scaffold background is black for the TikTok-like feed experience
    return Scaffold(
      backgroundColor: Colors.black, // Explicitly black
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
      ),
      body: Obx(() {
        if (controller.videos.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pinkAccent),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: controller.videos.length,
          onPageChanged: (index) {
            controller.onVideoPageChanged(index);
          },
          itemBuilder: (context, index) {
            final video = controller.videos[index];
            // Ensure the controller is put into GetX with a unique tag before accessing it
            Get.put(ReelController(video), tag: video.id, permanent: true);
            return VideoPlayerWidget(video: video);
          },
        );
      }),
    );
  }
}

// ----------------------------------------------------
// CART VIEW
// ----------------------------------------------------

class CartItemCard extends GetView<CartController> {
  final CartItem item;

  const CartItemCard({required this.item, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getProductIcon(item.product.name),
                  color: Colors.pink,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unit Price: \$${item.product.price.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      'Total: \$${(item.product.price * item.quantity.value).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () => controller.decrementQuantity(item),
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      '${item.quantity.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => controller.incrementQuantity(item),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => controller.removeItem(item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartView extends GetView<CartController> {
  const CartView({Key? key}) : super(key: key);

  Widget _buildSummaryRow(String title, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? Colors.pink : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Shopping Cart'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      // Explicitly set light background for readability
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        if (controller.cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your cart is empty!',
                  style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find products in the Reels feed.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: controller.cartItems.length,
                itemBuilder: (context, index) {
                  return CartItemCard(item: controller.cartItems[index]);
                },
              ),
            ),

            // Cart Summary and Checkout
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSummaryRow('Subtotal', controller.subtotal.value),
                  _buildSummaryRow('Est. Tax', controller.tax.value),
                  const Divider(),
                  _buildSummaryRow(
                    'Grand Total',
                    controller.total.value,
                    isTotal: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.cartItems.isNotEmpty) {
                          Get.snackbar(
                            'Checkout Successful!',
                            'Your purchase of \$${controller.total.value.toStringAsFixed(2)} has been processed.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.pink,
                            colorText: Colors.white,
                          );
                          // Clear the cart after simulated successful checkout
                          controller.clearCart();
                        } else {
                          Get.snackbar(
                            'Cart Empty',
                            'Please add items to your cart before proceeding.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ----------------------------------------------------
// PROFILE VIEW
// ----------------------------------------------------

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Explicitly set light background for readability
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.pinkAccent,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                '@ShopperAI_123',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI-Powered Shopper | 1,200 Followers',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: Colors.red),
                title: const Text('Liked Reels'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Get.snackbar(
                    'Feature',
                    'Access your liked videos.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.local_offer_outlined,
                  color: Colors.green,
                ),
                title: const Text('Seller Tools'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Get.snackbar(
                    'Feature',
                    'AI Tagging and Inventory Management.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('Order History'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Get.snackbar(
                    'Feature',
                    'View past purchases.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Mock Search View (Now readable)
class SearchView extends StatelessWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Explicitly set light background for readability
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Search & Explore'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.compass_calibration, size: 80, color: Colors.pink),
            const SizedBox(height: 16),
            Text(
              'Explore new Reels and Products!',
              style: TextStyle(fontSize: 22, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'Search feature coming soon...',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// MAIN APP NAVIGATION WRAPPER
// ----------------------------------------------------

class MainAppWrapper extends GetView<RootController> {
  const MainAppWrapper({Key? key}) : super(key: key);

  // Define the pages for the BottomNavigationBar
  final List<Widget> _pages = const [
    FeedView(), // Index 0
    SearchView(), // Index 1
    CartView(), // Index 2
    ProfileView(), // Index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: _pages,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changePage,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.video_collection_outlined),
              activeIcon: Icon(Icons.video_collection),
              label: 'Reels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 5. BINDINGS
// ----------------------------------------------------

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<RootController>(RootController());
    Get.lazyPut<FeedController>(() => FeedController(), fenix: true);
    Get.lazyPut<CartController>(() => CartController(), fenix: true);
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
      title: 'ReelCart AI Shoppable Video MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Set a neutral default color (views will override as needed)
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Arial',
      ),
      initialBinding: AppBinding(),
      home: const MainAppWrapper(),
    );
  }
}
