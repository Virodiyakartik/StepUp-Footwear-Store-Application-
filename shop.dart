import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'cart.dart';
import 'invoice_service.dart';

class ShopScreen extends StatefulWidget {
  final Set<String> wishlistedIds;
  final Function(Map<String, dynamic>) onAddToCart;
  final Function(String) onToggleWishlist;
  final String? initialBrand;
  final String? initialCategory;
  final String userId;
  final String userName;
  final Map<String, dynamic>? currentUser;

  const ShopScreen({
    super.key,
    required this.wishlistedIds,
    required this.onAddToCart,
    required this.onToggleWishlist,
    this.initialBrand,
    this.initialCategory,
    this.userId = 'GUEST',
    this.userName = 'Customer',
    this.currentUser,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late Set<String> _wishlisted;
  final TextEditingController _searchController = TextEditingController();

  String _selectedBrand = 'All Brands';
  String _selectedSize = 'All Sizes';
  String _selectedColor = 'All Colors';
  String _selectedMaxPrice = 'Max Price';
  String _searchQuery = '';
  bool _isLoadingSheet = false;

  final List<String> _brands = ['All Brands', 'Puma', 'Nike', 'Adidas', 'StepUp', 'Heritage Derby'];
  final List<String> _sizes = ['All Sizes', '6', '7', '8', '9', '10', '11'];
  final List<String> _colors = ['All Colors', 'Black', 'White', 'Blue', 'Red', 'Grey', 'Brown'];
  final List<String> _priceFilters = ['Max Price', '1500', '3000', '5000', '10000', '15000'];

  // Default original 6 products (untouched)
  final List<Map<String, dynamic>> _defaultProducts = [
    {
      'id': 'PROD_1',
      'title': 'Puma Smash Classic',
      'brand': 'Puma',
      'size': '7,8,9,10',
      'color': 'Black',
      'rating': 4.8,
      'reviews_count': 124,
      'price': 4999,
      'original_price': 6999,
      'image_url': 'assets/Puma.jpg',
      'description': '100% Original Brand • Softfoam+ comfort cushioned sole • Breathable leather upper for everyday rotation.',
    },
    {
      'id': 'PROD_2',
      'title': 'Air Jordan Retro High',
      'brand': 'Nike',
      'size': '8,9,10,11',
      'color': 'Red',
      'rating': 4.9,
      'reviews_count': 342,
      'price': 13499,
      'original_price': 16999,
      'image_url': 'assets/Nikw.jpg',
      'description': 'Iconic basketball high top with encapsulated air-sole cushioning and genuine leather finish.',
    },
    {
      'id': 'PROD_3',
      'title': 'Ultra Boost Velocity',
      'brand': 'Adidas',
      'size': '6,7,8,9',
      'color': 'White',
      'rating': 4.7,
      'reviews_count': 89,
      'price': 11999,
      'original_price': 14999,
      'image_url': 'assets/Nike 2.jpg',
      'description': 'Energy returning boost midsole combined with flexible primeknit mesh for ultimate comfort.',
    },
    {
      'id': 'PROD_4',
      'title': 'Street Rebel Chunky',
      'brand': 'StepUp',
      'size': '7,8,9',
      'color': 'Grey',
      'rating': 4.5,
      'reviews_count': 64,
      'price': 4499,
      'original_price': 5999,
      'image_url': 'assets/7cd0eb294e3a76c457f580a4ecd7c22d.jpg',
      'description': 'Bold streetwear silhouette engineered with chunky non-slip rubber tread and athletic shock absorb.',
    },
    {
      'id': 'PROD_5',
      'title': 'Ferrari Speed Drift Track',
      'brand': 'Puma',
      'size': '8,9,10',
      'color': 'Red',
      'rating': 4.8,
      'reviews_count': 110,
      'price': 8999,
      'original_price': 10999,
      'image_url': 'assets/8d49aa5506b868459a2542a99b08fcfe.jpg',
      'description': 'Scuderia Ferrari motorsport inspired aerodynamics, rounded driver heel and low profile grip.',
    },
    {
      'id': 'PROD_6',
      'title': 'Royal Monk Oxford',
      'brand': 'Heritage Derby',
      'size': '7,8,9,10,11',
      'color': 'Brown',
      'rating': 4.9,
      'reviews_count': 45,
      'price': 6999,
      'original_price': 8999,
      'image_url': 'assets/009356a1daa681ee3225d1f85369927b.jpg',
      'description': 'Handcrafted pure burnished leather featuring signature dual brass monk buckles for formal suits.',
    },
  ];

  List<Map<String, dynamic>> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _wishlisted = Set<String>.from(widget.wishlistedIds);
    if (widget.initialBrand != null && widget.initialBrand!.isNotEmpty) {
      _selectedBrand = widget.initialBrand!;
      if (!_brands.contains(widget.initialBrand!)) {
        _brands.add(widget.initialBrand!);
      }
    }
    _allProducts = List<Map<String, dynamic>>.from(_defaultProducts);
    _loadLiveSheetProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveSheetProducts() async {
    setState(() => _isLoadingSheet = true);
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}?action=getallproducts'))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['status'] == 'SUCCESS') {
          final List sheetList = decoded['data'] ?? [];
          List<Map<String, dynamic>> combined = [];

          for (var item in sheetList) {
            final shoeId = (item['shoe_id'] ?? '').toString();
            final isAlreadyInDefault = _defaultProducts.any((p) => p['id'] == shoeId);

            if (!isAlreadyInDefault && shoeId.isNotEmpty) {
              combined.add({
                'id': shoeId,
                'title': item['title'] ?? 'Custom Shoe',
                'brand': item['brand'] ?? 'StepUp',
                'size': item['size'] ?? '7,8,9,10',
                'color': item['category'] ?? 'Custom',
                'rating': 5.0,
                'reviews_count': 1,
                'price': (item['price'] as num?)?.toInt() ?? 4999,
                'original_price': ((item['price'] as num?)?.toInt() ?? 4999) + 1500,
                'image_url': (item['image_url'] ?? '').toString().isNotEmpty ? item['image_url'] : 'assets/Puma.jpg',
                'description': item['description'] ?? 'Official StepUp Collection release.',
              });

              final brandName = item['brand'].toString();
              if (brandName.isNotEmpty && !_brands.contains(brandName)) {
                _brands.add(brandName);
              }
            }
          }

          combined.addAll(_defaultProducts);

          if (mounted) {
            setState(() {
              _allProducts = combined;
              _isLoadingSheet = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSheet = false);
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((shoe) {
      final matchesBrand =
          _selectedBrand == 'All Brands' || shoe['brand'] == _selectedBrand;
      final matchesSize = _selectedSize == 'All Sizes' ||
          (shoe['size'] as String).split(',').map((e) => e.trim()).contains(_selectedSize);
      final matchesColor =
          _selectedColor == 'All Colors' || shoe['color'] == _selectedColor;
      final matchesPrice = _selectedMaxPrice == 'Max Price' ||
          (shoe['price'] as int) <= int.parse(_selectedMaxPrice);
      final matchesSearch = _searchQuery.isEmpty ||
          shoe['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          shoe['brand'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesBrand && matchesSize && matchesColor && matchesPrice && matchesSearch;
    }).toList();
  }

  void _toggleWishlistAndSave(Map<String, dynamic> shoe) {
    final shoeId = shoe['id'].toString();
    setState(() {
      if (_wishlisted.contains(shoeId)) {
        _wishlisted.remove(shoeId);
        ApiService.removeFromWishlist(userId: widget.userId, shoeId: shoeId);
      } else {
        _wishlisted.add(shoeId);
        ApiService.addToWishlist(
          userId: widget.userId,
          shoeId: shoeId,
          shoeName: shoe['title'],
          price: shoe['price'] as int,
          imageUrl: shoe['image_url'],
        );
      }
    });
    widget.onToggleWishlist(shoeId);
  }

  void _openProductDetailsModal(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductDetailsCheckoutModal(
        product: product,
        userId: widget.userId,
        userName: widget.userName,
        currentUser: widget.currentUser,
        onAddToCart: widget.onAddToCart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int gridCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
    final double cardRatio = screenWidth < 400 ? 0.58 : (screenWidth > 600 ? 0.68 : 0.62);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        elevation: 0,
        toolbarHeight: 52,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1C30), size: 16),
          onPressed: () => Navigator.pop(context, _wishlisted),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0037B0)]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 6),
            const Text(
              'STEPUP COLLECTION',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.0,
                color: Color(0xFF0B1C30),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0037B0), size: 20),
            tooltip: 'Sync Google Sheet Shoes',
            onPressed: _loadLiveSheetProducts,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.white,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDropdown(_brands, _selectedBrand, (val) => setState(() => _selectedBrand = val!)),
                      const SizedBox(width: 6),
                      _buildDropdown(_sizes, _selectedSize, (val) => setState(() => _selectedSize = val!)),
                      const SizedBox(width: 6),
                      _buildDropdown(_colors, _selectedColor, (val) => setState(() => _selectedColor = val!)),
                      const SizedBox(width: 6),
                      _buildDropdown(
                        _priceFilters,
                        _selectedMaxPrice,
                            (val) => setState(() => _selectedMaxPrice = val!),
                        format: (v) => v == 'Max Price' ? 'Max Price' : 'Under ₹$v',
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedBrand = 'All Brands';
                          _selectedSize = 'All Sizes';
                          _selectedColor = 'All Colors';
                          _selectedMaxPrice = 'Max Price';
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                        child: const Text('Reset', style: TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 12.5, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search collection, models...',
                      hintStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11.5),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF434655), size: 17),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 15, color: Color(0xFF434655)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProducts.length} PRODUCTS FOUND',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Color(0xFF434655),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_isLoadingSheet)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFF0037B0)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(
              child: Text('No products match your criteria.', style: TextStyle(color: Color(0xFF747686), fontWeight: FontWeight.w600)),
            )
                : RefreshIndicator(
              onRefresh: _loadLiveSheetProducts,
              color: const Color(0xFF0037B0),
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: _filteredProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  childAspectRatio: cardRatio,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final shoe = _filteredProducts[index];
                  final isWish = _wishlisted.contains(shoe['id']);
                  final isLocal = !(shoe['image_url'] ?? '').toString().startsWith('http');

                  return GestureDetector(
                    onTap: () => _openProductDetailsModal(shoe),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.025),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 11,
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: isLocal
                                      ? Image.asset(shoe['image_url'], fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.black26))
                                      : Image.network(
                                    shoe['image_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.black26),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => _toggleWishlistAndSave(shoe),
                                    child: CircleAvatar(
                                      radius: 13,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        isWish ? Icons.favorite : Icons.favorite_border,
                                        size: 14,
                                        color: isWish ? const Color(0xFFF43F5E) : const Color(0xFF434655),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      shoe['color'].toString().toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shoe['brand'].toString().toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF0037B0),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        shoe['title'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF0B1C30),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 11),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${shoe['rating']}',
                                            style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 9.5, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '(${shoe['reviews_count']})',
                                            style: const TextStyle(color: Color(0xFF747686), fontSize: 9),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Sizes: ${shoe['size']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xFF747686), fontSize: 9),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${shoe['price']}',
                                        style: const TextStyle(
                                          color: Color(0xFF0B1C30),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 28,
                                    child: ElevatedButton(
                                      onPressed: () => _openProductDetailsModal(shoe),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFEFF4FF),
                                        foregroundColor: const Color(0xFF0037B0),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text(
                                        'VIEW & BUY',
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items,
      String selected,
      ValueChanged<String?> onChanged, {
        String Function(String)? format,
      }) {
    final String safeValue = items.contains(selected) ? selected : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          dropdownColor: Colors.white,
          isDense: true,
          style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 11, fontWeight: FontWeight.bold),
          items: items.toSet().map((val) {
            return DropdownMenuItem(
              value: val,
              child: Text(format != null ? format(val) : val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ProductDetailsCheckoutModal extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onAddToCart;
  final String userId;
  final String userName;
  final Map<String, dynamic>? currentUser;

  const _ProductDetailsCheckoutModal({
    required this.product,
    required this.onAddToCart,
    required this.userId,
    required this.userName,
    this.currentUser,
  });

  @override
  State<_ProductDetailsCheckoutModal> createState() => _ProductDetailsCheckoutModalState();
}

class _ProductDetailsCheckoutModalState extends State<_ProductDetailsCheckoutModal> {
  bool _isCheckoutMode = false;
  bool _isSubmittingOrder = false;
  bool _isAddingToBag = false;
  String _selectedSize = '7';

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _selectedState = 'Gujarat';
  bool _smsUpdates = true;
  bool _mailingList = true;
  String _paymentMethod = 'COD';

  final _upiIdCtrl = TextEditingController();
  final _upiRefCtrl = TextEditingController();

  final List<String> _states = const [
    'Gujarat',
    'Maharashtra',
    'Delhi',
    'Karnataka',
    'Rajasthan',
    'Punjab',
    'Madhya Pradesh',
    'Uttar Pradesh',
    'Tamil Nadu',
    'West Bengal',
  ];

  final _reviewNameCtrl = TextEditingController();
  final _reviewCommentCtrl = TextEditingController();
  int _newRating = 5;
  bool _isSubmittingReview = false;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    final sizes = (widget.product['size'] as String).split(',');
    if (sizes.isNotEmpty) _selectedSize = sizes.first.trim();
    _reviewNameCtrl.text = widget.userName;

    if (widget.currentUser != null) {
      final names = (widget.currentUser!['name'] ?? '').toString().split(' ');
      _firstNameCtrl.text = names.isNotEmpty ? names.first : '';
      _lastNameCtrl.text = names.length > 1 ? names.sublist(1).join(' ') : '';
      _emailCtrl.text = (widget.currentUser!['email'] ?? '').toString();

      String rawPhone = (widget.currentUser!['phone_number'] ?? '').toString().replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '').trim();
      if (rawPhone.startsWith('91') && rawPhone.length > 10) {
        rawPhone = rawPhone.substring(2);
      }
      _phoneCtrl.text = rawPhone;
    }
    _fetchLiveReviews();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _cityCtrl.dispose();
    _upiIdCtrl.dispose();
    _upiRefCtrl.dispose();
    _reviewNameCtrl.dispose();
    _reviewCommentCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveReviews() async {
    final sheetReviews = await ApiService.getReviews(widget.product['id'].toString());
    if (mounted) {
      setState(() {
        if (sheetReviews.isNotEmpty) {
          _reviews = sheetReviews;
        } else {
          _reviews = [
            {'user_name': 'Rahul Sharma', 'rating': 5, 'review_text': 'Original product quality! Best fitting.'},
            {'user_name': 'Aman Patel', 'rating': 4, 'review_text': 'Sole is extremely soft and bouncy.'},
          ];
        }
      });
    }
  }

  Future<void> _submitReviewToSheet() async {
    final author = _reviewNameCtrl.text.trim();
    final comment = _reviewCommentCtrl.text.trim();

    if (author.isEmpty || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and comment!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmittingReview = true);

    final res = await ApiService.addReview(
      shoeId: widget.product['id'].toString(),
      userId: widget.userId,
      userName: author,
      rating: _newRating,
      reviewText: comment,
    );

    if (!mounted) return;
    setState(() => _isSubmittingReview = false);

    if (res['status'] == 'SUCCESS') {
      setState(() {
        _reviews.insert(0, {
          'user_name': author,
          'rating': _newRating,
          'review_text': comment,
        });
        _reviewCommentCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review saved successfully!'), backgroundColor: Color(0xFF0037B0)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to submit review!'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _handleAddToBag() async {
    setState(() => _isAddingToBag = true);

    final item = Map<String, dynamic>.from(widget.product)..['selected_size'] = _selectedSize;
    widget.onAddToCart(item);

    final res = await ApiService.addToCart(
      userId: widget.userId,
      shoeId: (widget.product['id'] ?? '').toString(),
      shoeName: (widget.product['title'] ?? '').toString(),
      size: _selectedSize,
      quantity: 1,
      price: (widget.product['price'] as num?)?.toInt() ?? 0,
    );

    if (!mounted) return;
    setState(() => _isAddingToBag = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                res['status'] == 'SUCCESS'
                    ? '${widget.product['title']} added & saved to Cart!'
                    : '${widget.product['title']} added to your bag!',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0037B0),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW BAG ➔',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(
                  cartItems: [item],
                  currentUser: widget.currentUser,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _placeDirectOrder() async {
    final phoneText = _phoneCtrl.text.trim();

    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        phoneText.isEmpty ||
        _pinCtrl.text.trim().isEmpty ||
        _address1Ctrl.text.trim().isEmpty ||
        _cityCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all mandatory shipping fields marked with *'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (phoneText.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number must be exactly 10 digits!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // STRICT UPI VALIDATION (Length & @ Check)
    if (_paymentMethod == 'UPI') {
      final upiId = _upiIdCtrl.text.trim();
      final upiRef = _upiRefCtrl.text.trim();

      if (upiId.isEmpty || !upiId.contains('@') || upiId.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid UPI ID (e.g. yourname@okhdfcbank)'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (upiRef.length != 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI Reference (UTR) must be exactly 12 digits!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmittingOrder = true);

    // Clean 6-digit order ID
    final int sixDigit = 100000 + (DateTime.now().millisecondsSinceEpoch % 900000);
    final orderId = 'ORD_$sixDigit';

    final customerName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
    final fullAddress = '${_address1Ctrl.text.trim()}, ${_address2Ctrl.text.trim().isNotEmpty ? '${_address2Ctrl.text.trim()}, ' : ''}${_cityCtrl.text.trim()}, $_selectedState - ${_pinCtrl.text.trim()} (Phone: $phoneText)';
    final totalAmount = (widget.product['price'] as num?)?.toInt() ?? 0;

    final paymentDetails = _paymentMethod == 'UPI'
        ? 'UPI [Sender: ${_upiIdCtrl.text.trim()} | UTR: ${_upiRefCtrl.text.trim()}]'
        : 'Cash on Delivery (COD)';

    final res = await ApiService.placeOrder(
      orderId: orderId,
      userId: widget.userId,
      shoeId: (widget.product['id'] ?? '').toString(),
      shoeName: (widget.product['title'] ?? '').toString(),
      size: _selectedSize,
      quantity: 1,
      totalAmount: totalAmount,
      shippingAddress: '$customerName | $fullAddress | Pay: $paymentDetails',
      orderStatus: 'Confirmed',
    );

    if (!mounted) return;
    setState(() => _isSubmittingOrder = false);
    Navigator.pop(context);

    final orderDate = DateTime.now().toString().substring(0, 10);
    final invoiceItems = [
      Map<String, dynamic>.from(widget.product)
        ..['selected_size'] = _selectedSize
        ..['quantity'] = 1
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF0037B0)),
            SizedBox(width: 8),
            Text('Order Confirmed!', style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: #$orderId\n'
                  'Item: ${widget.product['title']} (UK $_selectedSize)\n'
                  'Recipient: $customerName\n'
                  'Payment: $paymentDetails\n'
                  'Total: ₹$totalAmount (GST Included)\n\n'
                  '${res['status'] == 'SUCCESS' ? '✓ Saved to Google Sheet Orders table!' : 'Order recorded locally.'}',
              style: const TextStyle(color: Color(0xFF434655), height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  InvoiceService.generateAndDownloadInvoice(
                    orderId: orderId,
                    date: orderDate,
                    customerName: customerName,
                    customerEmail: _emailCtrl.text.trim(),
                    customerPhone: phoneText,
                    customerAddress: fullAddress,
                    paymentMethod: paymentDetails,
                    items: invoiceItems,
                    subtotal: totalAmount,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                label: const Text(
                  'DOWNLOAD INVOICE (PDF)',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0037B0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OKAY', style: TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isCheckoutMode ? 'CHECKOUT (STEPUP SECURE)' : 'PRODUCT DETAILS',
                style: const TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF434655), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: _isCheckoutMode
                  ? _buildPumaShippingFlow()
                  : _buildProductDetailsView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsView() {
    final sizes = (widget.product['size'] as String).split(',');
    final isLocal = !(widget.product['image_url'] ?? '').toString().startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 110,
                height: 110,
                color: const Color(0xFFEFF4FF),
                padding: const EdgeInsets.all(6),
                child: isLocal
                    ? Image.asset(widget.product['image_url'], fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.black26))
                    : Image.network(
                  widget.product['image_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.black26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product['brand'].toString().toUpperCase(),
                    style: const TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.product['title'],
                    style: const TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.product['rating']} (${_reviews.length} reviews)',
                        style: const TextStyle(color: Color(0xFF434655), fontSize: 10.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${widget.product['price']}',
                    style: const TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Color: ${widget.product['color']}',
                    style: const TextStyle(color: Color(0xFF747686), fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Description:', style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.bold, fontSize: 11.5)),
        const SizedBox(height: 3),
        Text(widget.product['description'], style: const TextStyle(color: Color(0xFF434655), fontSize: 11, height: 1.3)),
        const SizedBox(height: 12),
        const Text('Select Shoe Size:', style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.bold, fontSize: 11.5)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: sizes.map((s) {
            final sz = s.trim();
            final isSel = _selectedSize == sz;
            return ChoiceChip(
              label: Text('UK $sz'),
              selected: isSel,
              selectedColor: const Color(0xFF0037B0),
              labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF0B1C30), fontWeight: FontWeight.bold, fontSize: 11),
              onSelected: (_) => setState(() => _selectedSize = sz),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAddingToBag ? null : _handleAddToBag,
                icon: _isAddingToBag
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF0037B0), strokeWidth: 2))
                    : const Icon(Icons.shopping_bag_outlined, size: 15, color: Color(0xFF0037B0)),
                label: Text(
                  _isAddingToBag ? 'SAVING...' : 'ADD TO BAG',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF0037B0)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0037B0), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isCheckoutMode = true),
                icon: const Icon(Icons.flash_on, size: 15, color: Colors.white),
                label: const Text(
                  'BUY NOW',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0037B0),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xFFE2E8F0), height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Customer Reviews', style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.bold, fontSize: 12.5)),
            Text('${_reviews.length} total', style: const TextStyle(color: Color(0xFF0037B0), fontSize: 10.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        if (_reviews.isEmpty)
          const Text('No reviews yet. Write one below!', style: TextStyle(color: Color(0xFF747686), fontSize: 10.5))
        else
          ..._reviews.map((rev) {
            final authorName = (rev['user_name'] ?? rev['name'] ?? 'Customer').toString();
            final comment = (rev['review_text'] ?? rev['comment'] ?? '').toString();
            final ratingVal = (rev['rating'] as num?)?.toInt() ?? 5;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(authorName, style: const TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.bold, fontSize: 11)),
                      Row(
                        children: List.generate(
                          ratingVal,
                              (i) => const Icon(Icons.star, color: Colors.amber, size: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(comment, style: const TextStyle(color: Color(0xFF434655), fontSize: 10.5)),
                ],
              ),
            );
          }),
        const SizedBox(height: 14),
        const Text('Leave Feedback & Review:', style: TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.bold, fontSize: 11.5)),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text('Rating: ', style: TextStyle(color: Color(0xFF434655), fontSize: 10.5, fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: _newRating,
              dropdownColor: Colors.white,
              isDense: true,
              style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
              items: [5, 4, 3, 2, 1].map((r) => DropdownMenuItem(value: r, child: Text('$r Stars ⭐'))).toList(),
              onChanged: (val) => setState(() => _newRating = val!),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _reviewNameCtrl,
          style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 11.5),
          decoration: const InputDecoration(
            hintText: 'Your Name',
            hintStyle: TextStyle(color: Color(0xFF747686), fontSize: 11),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: EdgeInsets.all(10),
            border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _reviewCommentCtrl,
          style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 11.5),
          decoration: const InputDecoration(
            hintText: 'Write feedback...',
            hintStyle: TextStyle(color: Color(0xFF747686), fontSize: 11),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: EdgeInsets.all(10),
            border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 34,
          child: ElevatedButton(
            onPressed: _isSubmittingReview ? null : _submitReviewToSheet,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0037B0), foregroundColor: Colors.white),
            child: _isSubmittingReview
                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('SUBMIT FEEDBACK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildPumaShippingFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isCheckoutMode = false),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircleAvatar(
                radius: 11,
                backgroundColor: Color(0xFFEFF4FF),
                child: Icon(Icons.arrow_back, size: 13, color: Color(0xFF0037B0)),
              ),
              SizedBox(width: 6),
              Text(
                'BACK TO DETAILS',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xFF0B1C30),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildOrderSummarySideCard(),
        const SizedBox(height: 14),
        _buildShippingFormFields(),
      ],
    );
  }

  Widget _buildShippingFormFields() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SHIPPING',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFF0B1C30),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ORDERING AS:',
                  style: TextStyle(color: Color(0xFF434655), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.currentUser != null ? (widget.currentUser!['name'] ?? 'MEMBER').toString() : 'GUEST USER',
                  style: const TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.w900, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildFormField('First Name *', _firstNameCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _buildFormField('Last Name *', _lastNameCtrl)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(flex: 5, child: _buildFormField('Email *', _emailCtrl, keyboard: TextInputType.emailAddress)),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 12, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'PHONE (10 Digits) *',
                    counterText: '',
                    labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 10.5, fontWeight: FontWeight.bold),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.bold),
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.all(10),
                    fillColor: const Color(0xFFEFF4FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFormField('PIN Code *', _pinCtrl, keyboard: TextInputType.number),
          const SizedBox(height: 10),
          _buildFormField('Address Line 1 *', _address1Ctrl, icon: Icons.search),
          const SizedBox(height: 10),
          _buildFormField('Address Line 2 (Optional)', _address2Ctrl),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(flex: 5, child: _buildFormField('City *', _cityCtrl)),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedState,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 11.5, fontWeight: FontWeight.bold),
                      items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedState = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _smsUpdates,
            dense: true,
            onChanged: (v) => setState(() => _smsUpdates = v ?? true),
            title: const Text('Send me SMS tracking updates for this order', style: TextStyle(color: Color(0xFF434655), fontSize: 10.5)),
            activeColor: const Color(0xFF0037B0),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 10),
          const Text('PAYMENT METHOD', style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.w900, fontSize: 12)),
          RadioListTile<String>(
            value: 'COD',
            dense: true,
            groupValue: _paymentMethod,
            title: const Text('Cash on Delivery (COD)', style: TextStyle(color: Color(0xFF0B1C30), fontSize: 11.5, fontWeight: FontWeight.bold)),
            subtitle: const Text('Pay with cash when shoe arrives', style: TextStyle(color: Color(0xFF747686), fontSize: 9.5)),
            activeColor: const Color(0xFF0037B0),
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          RadioListTile<String>(
            value: 'UPI',
            dense: true,
            groupValue: _paymentMethod,
            title: const Text('UPI Instant Pay (GPay/PhonePe/Paytm)', style: TextStyle(color: Color(0xFF0B1C30), fontSize: 11.5, fontWeight: FontWeight.bold)),
            subtitle: const Text('Direct payment with Transaction ID / UTR', style: TextStyle(color: Color(0xFF747686), fontSize: 9.5)),
            activeColor: const Color(0xFF0037B0),
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),

          // PERFECTED UPI INPUT CONTAINER WITH EXACT VALIDATIONS
          if (_paymentMethod == 'UPI') ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0037B0).withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.qr_code_scanner, color: Color(0xFF0037B0), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'STEPUP OFFICIAL UPI TRANSFER',
                        style: TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.w900, fontSize: 10.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('UPI ID: stepup@okhdfcbank', style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.w900, fontSize: 11)),
                        Text('VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 9)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 1. UPI ID Field (Max 45 chars, handles format like user@bank)
                  TextField(
                    controller: _upiIdCtrl,
                    maxLength: 45,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Your UPI ID (e.g. name@okhdfcbank) *',
                      counterText: '',
                      labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 10.5, fontWeight: FontWeight.bold),
                      suffixIcon: const Icon(Icons.alternate_email, color: Color(0xFF0037B0), size: 16),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. 12-Digit UPI Reference / UTR Field (Strictly 12 digits only)
                  TextField(
                    controller: _upiRefCtrl,
                    maxLength: 12,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                    decoration: InputDecoration(
                      labelText: '12-Digit UPI Ref / UTR No. *',
                      counterText: '',
                      hintText: 'e.g. 428901234567',
                      hintStyle: const TextStyle(color: Color(0xFFB0B3C7), fontSize: 11),
                      labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 10.5, fontWeight: FontWeight.bold),
                      suffixIcon: const Icon(Icons.pin, color: Color(0xFF0037B0), size: 16),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _isSubmittingOrder ? null : _placeDirectOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0037B0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _isSubmittingOrder
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                _paymentMethod == 'UPI' ? 'VERIFY UPI & CONFIRM ORDER' : 'PLACE ORDER (COD)',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySideCard() {
    final isLocal = !(widget.product['image_url'] ?? '').toString().startsWith('http');
    final price = widget.product['price'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'ORDER SUMMARY',
                style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8),
              ),
              Text('1 item', style: TextStyle(color: Color(0xFF0037B0), fontSize: 10.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 50,
                  height: 50,
                  color: const Color(0xFFEFF4FF),
                  padding: const EdgeInsets.all(4),
                  child: isLocal
                      ? Image.asset(widget.product['image_url'] ?? '', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                      : Image.network(widget.product['image_url'] ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product['title'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                    Text('Size: UK $_selectedSize | Qty: 1', style: const TextStyle(color: Color(0xFF747686), fontSize: 9.5)),
                    Text('₹$price', style: const TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL AMOUNT (GST INCL)', style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.w900, fontSize: 11.5)),
              Text('₹$price', style: const TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {TextInputType? keyboard, IconData? icon}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 12, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 10.5, fontWeight: FontWeight.bold),
        suffixIcon: icon != null ? Icon(icon, color: const Color(0xFF434655), size: 15) : null,
        filled: true,
        fillColor: const Color(0xFFEFF4FF),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}