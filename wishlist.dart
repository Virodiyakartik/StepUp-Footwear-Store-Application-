import 'package:flutter/material.dart';
import 'api_service.dart';

class WishlistScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allProducts;
  final Set<String> wishlistedIds;
  final Function(Map<String, dynamic>) onAddToCart;
  final String userId;

  const WishlistScreen({
    super.key,
    required this.allProducts,
    required this.wishlistedIds,
    required this.onAddToCart,
    this.userId = 'GUEST',
  });

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Set<String> _wishlisted;
  List<Map<String, dynamic>> _displayProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _wishlisted = Set<String>.from(widget.wishlistedIds);
    _loadLiveWishlist();
  }

  // Google Sheet mathi live wishlist load karva mate
  Future<void> _loadLiveWishlist() async {
    setState(() => _isLoading = true);

    try {
      final sheetData = await ApiService.getWishlist(widget.userId);

      if (mounted) {
        if (sheetData.isNotEmpty) {
          // Google Sheet ma store thayela shoes ne UI format ma convert kare chhe
          List<Map<String, dynamic>> loadedList = [];
          Set<String> idSet = {};

          for (var row in sheetData) {
            final shoeId = (row['shoe_id'] ?? '').toString();
            if (shoeId.isNotEmpty) {
              idSet.add(shoeId);

              // Check karo ke local product list ma chhe ke nahi
              final localMatch = widget.allProducts.firstWhere(
                    (p) => p['id'].toString() == shoeId,
                orElse: () => {},
              );

              if (localMatch.isNotEmpty) {
                loadedList.add(localMatch);
              } else {
                // Jo local catalog ma na hoy to Sheet ma store details display thase
                loadedList.add({
                  'id': shoeId,
                  'title': row['shoe_name'] ?? 'Product Name',
                  'brand': 'STEPUP',
                  'price': (row['price'] as num?)?.toInt() ?? 4999,
                  'image_url': (row['image_url'] ?? '').toString().isNotEmpty
                      ? row['image_url']
                      : 'assets/Puma.jpg',
                });
              }
            }
          }

          setState(() {
            _wishlisted = idSet;
            _displayProducts = loadedList;
            _isLoading = false;
          });
        } else {
          // Jo sheet empty hoy to local state pramane filtered list
          setState(() {
            _displayProducts = widget.allProducts
                .where((p) => _wishlisted.contains(p['id'].toString()))
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _displayProducts = widget.allProducts
              .where((p) => _wishlisted.contains(p['id'].toString()))
              .toList();
          _isLoading = false;
        });
      }
    }
  }

  // Item Remove & Google Sheet Sync
  void _removeItem(String shoeId) {
    setState(() {
      _wishlisted.remove(shoeId);
      _displayProducts.removeWhere((item) => item['id'].toString() == shoeId);
    });

    // Background call to remove from Sheet
    ApiService.removeFromWishlist(userId: widget.userId, shoeId: shoeId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from Wishlist'),
        backgroundColor: Color(0xFF0B1C30),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int gridCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _wishlisted);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FF),
          elevation: 0,
          toolbarHeight: 65,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1C30), size: 18),
            onPressed: () => Navigator.pop(context, _wishlisted),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0037B0)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'WISHLIST (${_displayProducts.length})',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                  color: Color(0xFF0B1C30),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0037B0)),
              tooltip: 'Sync with Google Sheet',
              onPressed: _loadLiveWishlist,
            ),
            const SizedBox(width: 8),
          ],
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF0037B0)),
        )
            : _displayProducts.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF4FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    size: 48,
                    color: Color(0xFFF43F5E),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'YOUR WISHLIST IS EMPTY',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Color(0xFF0B1C30),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Save items to your wishlist to track favorite kicks and rapid drops.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF747686),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _wishlisted),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0037B0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'EXPLORE SHOES',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            : RefreshIndicator(
          color: const Color(0xFF0037B0),
          backgroundColor: Colors.white,
          onRefresh: _loadLiveWishlist,
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _displayProducts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              childAspectRatio: 0.62,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final shoe = _displayProducts[index];
              final String shoeId = shoe['id'].toString();
              final String imageUrl = (shoe['image_url'] ?? '').toString();
              final bool isLocal = !imageUrl.startsWith('http');

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: isLocal
                                  ? Image.asset(
                                imageUrl.isNotEmpty ? imageUrl : 'assets/Puma.jpg',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, color: Colors.black26),
                                ),
                              )
                                  : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, color: Colors.black26),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeItem(shoeId),
                              child: const CircleAvatar(
                                radius: 13,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.favorite, size: 14, color: Color(0xFFF43F5E)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (shoe['brand'] ?? 'STEPUP').toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0037B0),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (shoe['title'] ?? 'Shoe Name').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF0B1C30),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${shoe['price']}',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0B1C30),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onAddToCart(shoe);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${shoe['title']} moved to Bag!'),
                                      backgroundColor: const Color(0xFF0037B0),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0037B0),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text(
                                  'MOVE TO BAG',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}