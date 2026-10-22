import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'profile.dart';
import 'cart.dart';
import 'wishlist.dart';
import 'shop.dart';
import 'track_order.dart';
import 'notifications_screen.dart';
import 'admin/admin_login.dart';

class IndexScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUser;

  const IndexScreen({super.key, this.currentUser});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  int _selectedNavIndex = 0;
  final Set<String> _wishlistedIds = {};
  final List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _user;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Live Location State (નહીં મળે તો null રહેશે અને UI માંથી સંપૂર્ણ રિમૂવ થશે)
  String? _currentDeliverLocation;
  bool _isLoadingLocation = true;

  final List<Map<String, dynamic>> _allCatalogProducts = const [
    {
      'id': 'PROD_1',
      'title': 'Puma Smash Classic',
      'brand': 'Puma',
      'tag': 'CLASSIC',
      'price': 4999,
      'rating': 4.8,
      'image_url': 'assets/Puma.jpg',
      'category': 'Sneakers',
    },
    {
      'id': 'PROD_2',
      'title': 'Air Jordan Retro High',
      'brand': 'Nike',
      'tag': 'DEADSTOCK',
      'price': 13499,
      'rating': 4.9,
      'image_url': 'assets/Nikw.jpg',
      'category': 'Basketball',
    },
    {
      'id': 'PROD_3',
      'title': 'Ultra Boost Velocity',
      'brand': 'Adidas',
      'tag': 'HOT DROP',
      'price': 11999,
      'rating': 4.7,
      'image_url': 'assets/Nike 2.jpg',
      'category': 'Running',
    },
    {
      'id': 'PROD_4',
      'title': 'Street Rebel Chunky',
      'brand': 'StepUp',
      'tag': 'STREETWEAR',
      'price': 4499,
      'rating': 4.5,
      'image_url': 'assets/7cd0eb294e3a76c457f580a4ecd7c22d.jpg',
      'category': 'Streetwear',
    },
    {
      'id': 'PROD_5',
      'title': 'Ferrari Speed Drift Track',
      'brand': 'Puma',
      'tag': 'SPECIAL',
      'price': 8999,
      'rating': 4.8,
      'image_url': 'assets/8d49aa5506b868459a2542a99b08fcfe.jpg',
      'category': 'Motorsport',
    },
    {
      'id': 'PROD_6',
      'title': 'Royal Monk Oxford',
      'brand': 'Heritage Derby',
      'tag': 'FORMAL',
      'price': 6999,
      'rating': 4.9,
      'image_url': 'assets/009356a1daa681ee3225d1f85369927b.jpg',
      'category': 'Formal',
    },
  ];

  final List<Map<String, dynamic>> _trendingDrops = const [
    {
      'id': 'PROD_2',
      'title': 'Air Jordan Retro High',
      'brand': 'Nike',
      'tag': 'DEADSTOCK',
      'price': 13499,
      'rating': 4.9,
      'image_url': 'assets/Nikw.jpg',
    },
    {
      'id': 'PROD_3',
      'title': 'Ultra Boost Velocity',
      'brand': 'Adidas',
      'tag': 'HOT DROP',
      'price': 11999,
      'rating': 4.7,
      'image_url': 'assets/Nike 2.jpg',
    },
  ];

  final List<Map<String, dynamic>> _bestSellers = const [
    {
      'id': 'PROD_1',
      'title': 'Puma Smash Classic',
      'brand': 'Puma',
      'tag': 'BEST SELLER',
      'price': 4999,
      'rating': 4.8,
      'image_url': 'assets/Puma.jpg',
    },
    {
      'id': 'PROD_4',
      'title': 'Street Rebel Chunky',
      'brand': 'StepUp',
      'tag': 'POPULAR',
      'price': 4499,
      'rating': 4.5,
      'image_url': 'assets/7cd0eb294e3a76c457f580a4ecd7c22d.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser;
    _fetchLiveUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Live Location Fetcher (પ્રથમ ipwho.is અને બેકઅપ ipapi.co)
  Future<void> _fetchLiveUserLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // 1st Attempt: ipwho.is
      final response = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final city = (data['city'] ?? '').toString().trim();
          final region = (data['region'] ?? '').toString().trim();
          final postal = (data['postal'] ?? '').toString().trim();
          final country = (data['country'] ?? '').toString().trim();

          String loc = '';
          if (city.isNotEmpty) loc += '$city, ';
          if (region.isNotEmpty && region != city) loc += '$region ';
          if (postal.isNotEmpty) {
            loc += postal;
          } else if (country.isNotEmpty) {
            loc += country;
          }

          loc = loc.trim();
          if (loc.endsWith(',')) loc = loc.substring(0, loc.length - 1).trim();

          if (loc.isNotEmpty && mounted) {
            setState(() {
              _currentDeliverLocation = 'Deliver to $loc';
              _isLoadingLocation = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    // 2nd Backup Attempt: ipapi.co
    try {
      final res2 = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 3));

      if (res2.statusCode == 200) {
        final data2 = jsonDecode(res2.body);
        final city2 = (data2['city'] ?? '').toString().trim();
        final region2 = (data2['region'] ?? '').toString().trim();
        final postal2 = (data2['postal'] ?? '').toString().trim();

        String loc2 = '';
        if (city2.isNotEmpty) loc2 += '$city2, ';
        if (region2.isNotEmpty && region2 != city2) loc2 += '$region2 ';
        if (postal2.isNotEmpty) loc2 += postal2;

        loc2 = loc2.trim();
        if (loc2.endsWith(',')) loc2 = loc2.substring(0, loc2.length - 1).trim();

        if (loc2.isNotEmpty && mounted) {
          setState(() {
            _currentDeliverLocation = 'Deliver to $loc2';
            _isLoadingLocation = false;
          });
          return;
        }
      }
    } catch (_) {}

    // જો કોઈ લોકેશન ન મળે, તો નલ સેટ થશે અને UI માંથી સંપૂર્ણ રિમૂવ થઈ જશે
    if (mounted) {
      setState(() {
        _currentDeliverLocation = null;
        _isLoadingLocation = false;
      });
    }
  }

  List<Map<String, dynamic>> get _searchedResults {
    if (_searchQuery.isEmpty) return [];
    return _allCatalogProducts.where((shoe) {
      final titleMatch = shoe['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final brandMatch = shoe['brand'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return titleMatch || brandMatch;
    }).toList();
  }

  void _onAddToCart(Map<String, dynamic> shoe) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item['id'] == shoe['id']);
      if (existingIndex >= 0) {
        _cartItems[existingIndex]['quantity'] = (_cartItems[existingIndex]['quantity'] as int) + 1;
      } else {
        _cartItems.add(Map<String, dynamic>.from(shoe)..['quantity'] = 1);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${shoe['title']} added to your Bag!'),
        backgroundColor: const Color(0xFF0037B0),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleWishlist(String shoeId) {
    setState(() {
      if (_wishlistedIds.contains(shoeId)) {
        _wishlistedIds.remove(shoeId);
      } else {
        _wishlistedIds.add(shoeId);
      }
    });
  }

  void _navigateToShop({String? initialBrand}) async {
    final updated = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ShopScreen(
          wishlistedIds: _wishlistedIds,
          onAddToCart: _onAddToCart,
          onToggleWishlist: _toggleWishlist,
          initialBrand: initialBrand,
          userId: (_user?['user_id'] ?? 'GUEST').toString(),
          userName: (_user?['name'] ?? 'Customer').toString(),
          currentUser: _user,
        ),
      ),
    );
    if (updated != null) {
      setState(() => _wishlistedIds
        ..clear()
        ..addAll(updated));
    }
  }

  void _navigateToTrackOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackOrderScreen(currentUser: _user),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(currentUser: _user),
      ),
    );
  }

  void _navigateToCart() async {
    final updatedCart = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cartItems: _cartItems,
          currentUser: _user,
        ),
      ),
    );
    if (updatedCart != null) {
      setState(() => _cartItems
        ..clear()
        ..addAll(updatedCart));
    }
  }

  void _navigateToWishlist() async {
    final updated = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => WishlistScreen(
          allProducts: _allCatalogProducts,
          wishlistedIds: _wishlistedIds,
          onAddToCart: _onAddToCart,
          userId: (_user?['user_id'] ?? 'GUEST').toString(),
        ),
      ),
    );
    if (updated != null) {
      setState(() => _wishlistedIds
        ..clear()
        ..addAll(updated));
    }
  }

  void _navigateToProfileOrLogin() async {
    if (_user != null) {
      final updatedUser = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(user: _user!)),
      );
      if (updatedUser != null) {
        setState(() => _user = updatedUser);
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  String _getUserFirstLetter() {
    if (_user != null && _user!['name'] != null) {
      final String name = _user!['name'].toString().trim();
      if (name.isNotEmpty) {
        return name.substring(0, 1).toUpperCase();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final String userInitial = _getUserFirstLetter();
    final bool isSearching = _searchQuery.isNotEmpty;
    final searchResults = _searchedResults;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF0037B0)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'STEPUP',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFF0B1C30),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Home',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _navigateToNotifications,
                        icon: Badge(
                          backgroundColor: const Color(0xFFEF4444),
                          smallSize: 8,
                          child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0B1C30), size: 24),
                        ),
                        tooltip: 'Notifications',
                      ),
                      GestureDetector(
                        onTap: _navigateToProfileOrLogin,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: userInitial.isNotEmpty
                                ? const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF0037B0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : null,
                            color: userInitial.isEmpty ? const Color(0xFFE5EEFF) : null,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0037B0).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: userInitial.isNotEmpty
                                ? Text(
                              userInitial,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            )
                                : const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF0037B0),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Deliver Bar (Live Location જો સફળતાપૂર્વક મળશે તો જ દેખાશે, નહીંતર સંપૂર્ણ રિમૂવ થશે)
              Row(
                children: [
                  if (_currentDeliverLocation != null) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Color(0xFF0037B0),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _currentDeliverLocation!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B1C30),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _fetchLiveUserLocation,
                              child: const Icon(Icons.refresh, size: 14, color: Color(0xFF0037B0)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Track Order Button
                  GestureDetector(
                    onTap: _navigateToTrackOrder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6D5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.radar_rounded, size: 13, color: Color(0xFF9A4200)),
                          SizedBox(width: 4),
                          Text(
                            'TRACK ORDER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF9A4200),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hero Titles
              const Text(
                'Find Your Perfect Pair',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Curated heat for street & performance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF434655),
                ),
              ),
              const SizedBox(height: 16),

              // Active Brand & Shoes Search Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSearching ? const Color(0xFF0037B0) : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF434655), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                              style: const TextStyle(
                                color: Color(0xFF0B1C30),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search brand (Nike, Puma, Adidas...)',
                                hintStyle: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF747686),
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (isSearching)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              child: const Icon(Icons.close_rounded, color: Color(0xFF434655), size: 18),
                            )
                          else
                            const Icon(Icons.mic_none_rounded, color: Color(0xFF434655), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _navigateToShop(initialBrand: _searchQuery.isNotEmpty ? _searchQuery : null),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCE9FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF0037B0), size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Search Results
              if (isSearching) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search Results for "$_searchQuery"',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    Text(
                      '${searchResults.length} found',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0037B0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (searchResults.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 42, color: Color(0xFF747686)),
                        const SizedBox(height: 8),
                        Text(
                          'No shoes found for "$_searchQuery"',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF0B1C30),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try searching for Nike, Puma, Adidas, or StepUp',
                          style: TextStyle(fontSize: 12, color: Color(0xFF747686)),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: searchResults.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final shoe = searchResults[index];
                      final isFav = _wishlistedIds.contains(shoe['id']);
                      return _buildDropCard(shoe, isFav);
                    },
                  ),
                const SizedBox(height: 24),
              ] else ...[
                // Season Drop Hero Banner
                GestureDetector(
                  onTap: () => _navigateToShop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0037B0), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0037B0).withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'SEASON DROP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Spring Drop:\nUp to 40% OFF',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Exclusive retros & silhouettes',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _navigateToShop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0037B0),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.arrow_forward, size: 14),
                                label: const Text(
                                  'Shop Collection',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Transform.rotate(
                            angle: -0.25,
                            child: Image.asset(
                              'assets/7cd0eb294e3a76c457f580a4ecd7c22d.jpg',
                              height: 110,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Flash Deal of the Day Card
                GestureDetector(
                  onTap: () => _navigateToShop(initialBrand: 'Puma'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Color(0xFF9A4200), shape: BoxShape.circle),
                                  child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Flash Deal of the Day',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF0B1C30),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDBCA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '-35% OFF',
                                style: TextStyle(
                                  color: Color(0xFF9A4200),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Image.asset('assets/8d49aa5506b868459a2542a99b08fcfe.jpg', fit: BoxFit.contain),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PUMA MOTORSPORT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0037B0),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Ferrari Speed Drift Track',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0B1C30),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: const [
                                      Text(
                                        '₹8,999',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0B1C30),
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '₹10,999',
                                        style: TextStyle(
                                          fontSize: 11,
                                          decoration: TextDecoration.lineThrough,
                                          color: Color(0xFF434655),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 30,
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _navigateToShop(initialBrand: 'Puma'),
                                      icon: const Icon(Icons.shopping_bag_outlined, size: 13, color: Colors.white),
                                      label: const Text(
                                        'Claim Pair',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0B1C30),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Trending Drops Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trending Drops',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    InkWell(
                      onTap: () => _navigateToShop(),
                      child: const Text(
                        'See All ›',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0037B0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Trending Drops Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _trendingDrops.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final shoe = _trendingDrops[index];
                    final isFav = _wishlistedIds.contains(shoe['id']);
                    return _buildDropCard(shoe, isFav);
                  },
                ),
                const SizedBox(height: 24),

                // Best Sellers Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Best Sellers',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SHOP NOW',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0037B0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Best Sellers Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bestSellers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final shoe = _bestSellers[index];
                    final isFav = _wishlistedIds.contains(shoe['id']);
                    return _buildBestSellerCard(shoe, isFav);
                  },
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavTab(Icons.home_rounded, 'Home', 0, isActive: true),
            _buildNavTab(Icons.explore_outlined, 'Explore', 1, onTap: () => _navigateToShop()),
            _buildNavTab(Icons.favorite_border_rounded, 'Wishlist', 2, onTap: _navigateToWishlist, badge: _wishlistedIds.length),
            _buildNavTab(Icons.shopping_bag_outlined, 'Cart', 3, onTap: _navigateToCart, badge: _cartItems.length),
            _buildNavTab(Icons.person_outline_rounded, 'Profile', 4, onTap: _navigateToProfileOrLogin),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(IconData icon, String label, int idx, {bool isActive = false, VoidCallback? onTap, int badge = 0}) {
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _selectedNavIndex = idx),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            isLabelVisible: badge > 0,
            label: Text('$badge'),
            backgroundColor: const Color(0xFF0037B0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0037B0) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 20, color: isActive ? Colors.white : const Color(0xFF434655)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? const Color(0xFF0037B0) : const Color(0xFF434655),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropCard(Map<String, dynamic> shoe, bool isFav) {
    return GestureDetector(
      onTap: () => _navigateToShop(initialBrand: shoe['brand']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    shoe['tag'] ?? 'HOT',
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0037B0)),
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleWishlist(shoe['id']),
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: const Color(0xFFF8F9FF),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: isFav ? Colors.red : const Color(0xFF434655),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Image.asset(shoe['image_url'], fit: BoxFit.contain),
              ),
            ),
            Text(
              shoe['brand'],
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF434655)),
            ),
            const SizedBox(height: 2),
            Text(
              shoe['title'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${shoe['price']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF0B1C30),
                  ),
                ),
                GestureDetector(
                  onTap: () => _onAddToCart(shoe),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFF0037B0), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellerCard(Map<String, dynamic> shoe, bool isFav) {
    return GestureDetector(
      onTap: () => _navigateToShop(initialBrand: shoe['brand']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    shoe['tag'] ?? 'POPULAR',
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0037B0)),
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleWishlist(shoe['id']),
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: const Color(0xFFF8F9FF),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: isFav ? Colors.red : const Color(0xFF434655),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Image.asset(shoe['image_url'], fit: BoxFit.contain),
              ),
            ),
            Text(
              shoe['brand'],
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF434655)),
            ),
            const SizedBox(height: 2),
            Text(
              shoe['title'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${shoe['price']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF0B1C30),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '${shoe['rating']}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton.icon(
                onPressed: () => _onAddToCart(shoe),
                icon: const Icon(Icons.shopping_cart_outlined, size: 12, color: Colors.white),
                label: const Text(
                  'Add',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1C30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}