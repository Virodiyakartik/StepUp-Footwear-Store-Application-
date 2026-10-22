import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';
import '../index.dart';
import 'admin_users_screen.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminName;

  const AdminDashboardScreen({
    super.key,
    this.adminName = 'Kartik Virodiya',
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  int _userCount = 0;
  int _productCount = 0;
  int _orderCount = 0;
  int _reviewCount = 0;
  int _totalRevenue = 0;
  bool _isLoading = true;

  // Order status live counts
  int _pendingOrders = 0;
  int _acceptedOrders = 0;
  int _dispatchedOrders = 0;
  int _deliveredOrders = 0;
  int _cancelledOrders = 0;

  // Payment breakdown counts & amounts
  int _cashCount = 0;
  int _cashAmount = 0;
  int _onlineCount = 0;
  int _onlineAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadLiveSheetMetrics();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLiveSheetMetrics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final client = http.Client();
      final base = ApiService.baseUrl;

      final results = await Future.wait([
        client.get(Uri.parse('$base?action=getallusers')).timeout(const Duration(seconds: 6)),
        client.get(Uri.parse('$base?action=getallproducts')).timeout(const Duration(seconds: 6)),
        client.get(Uri.parse('$base?action=getallorders')).timeout(const Duration(seconds: 6)),
        client.get(Uri.parse('$base?action=getreviews')).timeout(const Duration(seconds: 6)),
      ]).whenComplete(() => client.close());

      final uRes = results[0];
      final pRes = results[1];
      final oRes = results[2];
      final rRes = results[3];

      int users = 0;
      int prods = 0;
      int orders = 0;
      int rev = 0;
      int revenue = 0;

      int pending = 0;
      int accepted = 0;
      int dispatched = 0;
      int delivered = 0;
      int cancelled = 0;

      int cashC = 0;
      int cashA = 0;
      int onlineC = 0;
      int onlineA = 0;

      if (uRes.statusCode == 200) {
        final d = jsonDecode(uRes.body);
        if (d['status'] == 'SUCCESS') users = (d['data'] as List).length;
      }

      if (pRes.statusCode == 200) {
        final d = jsonDecode(pRes.body);
        if (d['status'] == 'SUCCESS') prods = (d['data'] as List).length;
      }

      if (rRes.statusCode == 200) {
        final d = jsonDecode(rRes.body);
        if (d['status'] == 'SUCCESS') rev = (d['data'] as List).length;
      }

      if (oRes.statusCode == 200) {
        final d = jsonDecode(oRes.body);
        if (d['status'] == 'SUCCESS') {
          final list = d['data'] as List;
          orders = list.length;
          for (var item in list) {
            final amt = (item['total_amount'] as num?)?.toInt() ?? 0;
            revenue += amt;

            final status = (item['order_status'] ?? '').toString().toLowerCase();
            if (status.contains('cancel')) {
              cancelled++;
            } else if (status.contains('deliver')) {
              delivered++;
            } else if (status.contains('dispatch')) {
              dispatched++;
            } else if (status.contains('accept')) {
              accepted++;
            } else {
              pending++;
            }

            final shipping = (item['shipping_address'] ?? '').toString();
            if (shipping.contains('UPI')) {
              onlineC++;
              onlineA += amt;
            } else {
              cashC++;
              cashA += amt;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _userCount = users;
          _productCount = prods;
          _orderCount = orders;
          _reviewCount = rev;
          _totalRevenue = revenue;

          _pendingOrders = pending;
          _acceptedOrders = accepted;
          _dispatchedOrders = dispatched;
          _deliveredOrders = delivered;
          _cancelledOrders = cancelled;

          _cashCount = cashC;
          _cashAmount = cashA;
          _onlineCount = onlineC;
          _onlineAmount = onlineA;

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProfileScreen(adminName: widget.adminName),
      ),
    );
  }

  void _navigateToUsers() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())).then((_) => _loadLiveSheetMetrics());
  }

  void _navigateToProducts() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductsScreen())).then((_) => _loadLiveSheetMetrics());
  }

  void _navigateToOrders() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen())).then((_) => _loadLiveSheetMetrics());
  }

  void _navigateToPayments() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPaymentsScreen())).then((_) => _loadLiveSheetMetrics());
  }

  void _navigateToReviews() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewsScreen())).then((_) => _loadLiveSheetMetrics());
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 950;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1C30), size: 18),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const IndexScreen())),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0037B0)]),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'STEPUP ADMIN',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.1,
                color: Color(0xFF0B1C30),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF0037B0), size: 24),
            tooltip: 'Admin Profile',
            onPressed: _navigateToProfile,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0037B0), size: 22),
            tooltip: 'Sync Google Sheet',
            onPressed: _loadLiveSheetMetrics,
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: !isWide ? Drawer(width: 260, child: _buildSidebarContent()) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              child: _buildSidebarContent(),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0037B0), strokeWidth: 2.8))
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopSearchBar(),
                  const SizedBox(height: 12),
                  _buildAdminProfileBanner(),
                  const SizedBox(height: 16),
                  const Text(
                    'LIVE METRICS (GOOGLE SHEET)',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF434655),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStatsGrid(screenWidth),
                  const SizedBox(height: 16),

                  // --- 2 PIE CHARTS (PAYMENT & ORDERS) ---
                  _buildPieChartsSection(screenWidth),

                  const SizedBox(height: 18),
                  const Text(
                    'MANAGEMENT SECTIONS',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF434655),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildQuickActionsGrid(screenWidth),
                  const SizedBox(height: 20),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF434655), size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Search database records...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF747686)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminProfileBanner() {
    return InkWell(
      onTap: _navigateToProfile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0037B0), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0037B0).withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text(
                widget.adminName.isNotEmpty ? widget.adminName[0].toUpperCase() : 'A',
                style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0037B0)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.adminName,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'SUPER ADMIN • TAP TO VIEW PROFILE',
                    style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0037B0)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'STEPUP',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Color(0xFF0B1C30),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarItem(Icons.dashboard_rounded, 'Dashboard', isActive: true, onTap: () {}),
                _sidebarItem(Icons.account_circle_outlined, 'Admin Profile', onTap: _navigateToProfile),
                _sidebarItem(Icons.inventory_2_rounded, 'Products', onTap: _navigateToProducts),
                _sidebarItem(Icons.people_alt_rounded, 'Users', onTap: _navigateToUsers),
                _sidebarItem(Icons.shopping_bag_rounded, 'Orders', onTap: _navigateToOrders),
                _sidebarItem(Icons.credit_card_rounded, 'Payments', onTap: _navigateToPayments),
                _sidebarItem(Icons.star_rounded, 'Reviews', onTap: _navigateToReviews),
                const Divider(color: Color(0xFFE2E8F0), height: 20),
                _sidebarItem(Icons.storefront_rounded, 'Store', onTap: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx) => const IndexScreen()));
                }),
                _sidebarItem(Icons.logout_rounded, 'Logout', isDanger: true, onTap: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (ctx) => const IndexScreen()), (r) => false);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, {bool isActive = false, bool isDanger = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEFF4FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive ? const Border(left: BorderSide(color: Color(0xFF0037B0), width: 3.5)) : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isDanger ? const Color(0xFFEF4444) : (isActive ? const Color(0xFF0037B0) : const Color(0xFF747686)),
          size: 19,
        ),
        title: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isDanger ? const Color(0xFFEF4444) : (isActive ? const Color(0xFF0037B0) : const Color(0xFF0B1C30)),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatsGrid(double width) {
    int count = width > 1100 ? 5 : (width > 600 ? 3 : 2);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: count,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        _statCard('USERS', '$_userCount', Icons.people_alt_rounded, const Color(0xFF8B5CF6), onTap: _navigateToUsers),
        _statCard('PRODUCTS', '$_productCount', Icons.inventory_2_rounded, const Color(0xFF0037B0), onTap: _navigateToProducts),
        _statCard('ORDERS', '$_orderCount', Icons.shopping_bag_rounded, const Color(0xFF10B981), onTap: _navigateToOrders),
        _statCard('REVENUE', '₹$_totalRevenue', Icons.account_balance_wallet_rounded, const Color(0xFFF97316), onTap: _navigateToPayments),
        _statCard('REVIEWS', '$_reviewCount', Icons.star_rounded, const Color(0xFFFBBF24), onTap: _navigateToReviews),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF747686), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Text(value, style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF0B1C30), fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PIE CHARTS SECTION (PAYMENTS & ORDERS)
  // ==========================================
  Widget _buildPieChartsSection(double width) {
    final bool stack = width < 850;

    return Flex(
      direction: stack ? Axis.vertical : Axis.horizontal,
      children: [
        // 1. PAYMENT PIE CHART & AMOUNT BOXES
        Expanded(
          flex: stack ? 0 : 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('PAYMENT BREAKDOWN', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF0B1C30), fontWeight: FontWeight.w900, fontSize: 12.5)),
                    Text('UPI VS COD', style: TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.w800, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 14),

                // Donut/Pie Chart Graphic
                Center(
                  child: SizedBox(
                    width: 125,
                    height: 125,
                    child: CustomPaint(
                      painter: _PaymentPieChartPainter(
                        online: _onlineAmount.toDouble(),
                        cash: _cashAmount.toDouble(),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('TOTAL', style: TextStyle(color: Color(0xFF747686), fontSize: 9, fontWeight: FontWeight.w800)),
                            Text('₹$_totalRevenue', style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF0B1C30), fontSize: 13, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Boxes (Cash and Online)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDBCA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                CircleAvatar(radius: 4, backgroundColor: Color(0xFFF97316)),
                                SizedBox(width: 5),
                                Text('CASH (COD)', style: TextStyle(color: Color(0xFF9A4200), fontSize: 9.5, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('₹$_cashAmount', style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF9A4200), fontWeight: FontWeight.w900, fontSize: 15)),
                            Text('$_cashCount orders logged', style: const TextStyle(color: Color(0xFF9A4200), fontSize: 9.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                CircleAvatar(radius: 4, backgroundColor: Color(0xFF0037B0)),
                                SizedBox(width: 5),
                                Text('ONLINE UPI', style: TextStyle(color: Color(0xFF0037B0), fontSize: 9.5, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('₹$_onlineAmount', style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF0037B0), fontWeight: FontWeight.w900, fontSize: 15)),
                            Text('$_onlineCount orders verified', style: const TextStyle(color: Color(0xFF0037B0), fontSize: 9.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: stack ? 0 : 12, height: stack ? 12 : 0),

        // 2. ORDER STATUS PIE CHART
        Expanded(
          flex: stack ? 0 : 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('ORDER STATUS LIVE PIE', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF0B1C30), fontWeight: FontWeight.w900, fontSize: 12.5)),
                    Text('FULFILLMENT', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 14),

                // Donut/Pie Chart Graphic
                Center(
                  child: SizedBox(
                    width: 125,
                    height: 125,
                    child: CustomPaint(
                      painter: _OrderStatusPieChartPainter(
                        pending: _pendingOrders.toDouble(),
                        accepted: _acceptedOrders.toDouble(),
                        dispatched: _dispatchedOrders.toDouble(),
                        delivered: _deliveredOrders.toDouble(),
                        cancelled: _cancelledOrders.toDouble(),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('ORDERS', style: TextStyle(color: Color(0xFF747686), fontSize: 9, fontWeight: FontWeight.w800)),
                            Text('$_orderCount', style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF0B1C30), fontSize: 15, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Order Status Legend Indicators
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chartStatusChip('Pending', '$_pendingOrders', const Color(0xFFF59E0B)),
                    _chartStatusChip('Accepted', '$_acceptedOrders', const Color(0xFF0284C7)),
                    _chartStatusChip('Dispatched', '$_dispatchedOrders', const Color(0xFF8B5CF6)),
                    _chartStatusChip('Delivered', '$_deliveredOrders', const Color(0xFF10B981)),
                    _chartStatusChip('Cancelled', '$_cancelledOrders', const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chartStatusChip(String title, String count, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3.5, backgroundColor: col),
          const SizedBox(width: 5),
          Text(
            '$title: $count',
            style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(double width) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: width > 800 ? 2 : 1,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 3.2,
      children: [
        _actionCard('USERS DIRECTORY', 'Manage Google Sheet user accounts', Icons.people_alt_rounded, const Color(0xFF8B5CF6), _navigateToUsers),
        _actionCard('CATALOG PRODUCTS', 'Add shoes, prices, stocks & images', Icons.add_box_rounded, const Color(0xFF0037B0), _navigateToProducts),
        _actionCard('CUSTOMER ORDERS', 'Accept, dispatch or cancel live orders', Icons.shopping_bag_rounded, const Color(0xFF10B981), _navigateToOrders),
        _actionCard('PAYMENTS & BILLS', 'Check UTR verification & download PDF bills', Icons.credit_card_rounded, const Color(0xFFF97316), _navigateToPayments),
      ],
    );
  }

  Widget _actionCard(String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF0B1C30), fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF747686), fontSize: 10.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFC4C5D7), size: 13),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('© STEPUP FOOTWEAR, 2026', style: TextStyle(color: Color(0xFF747686), fontSize: 10, fontWeight: FontWeight.w600)),
          Text('SECURE CONSOLE', style: TextStyle(color: Color(0xFF0037B0), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==========================================
// CUSTOM PIE CHART PAINTERS (ZERO DEPENDENCY)
// ==========================================

class _PaymentPieChartPainter extends CustomPainter {
  final double online;
  final double cash;

  _PaymentPieChartPainter({required this.online, required this.cash});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = online + cash;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    final paintBg = Paint()
      ..color = const Color(0xFFEFF4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - (strokeWidth / 2), paintBg);

    if (total == 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2));
    double startAngle = -math.pi / 2;

    // Online Sweep (Blue)
    final onlineSweep = (online / total) * 2 * math.pi;
    final paintOnline = Paint()
      ..color = const Color(0xFF0037B0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, startAngle, onlineSweep, false, paintOnline);

    // Cash Sweep (Orange)
    final cashSweep = (cash / total) * 2 * math.pi;
    final paintCash = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, startAngle + onlineSweep, cashSweep, false, paintCash);
  }

  @override
  bool shouldRepaint(covariant _PaymentPieChartPainter oldDelegate) {
    return oldDelegate.online != online || oldDelegate.cash != cash;
  }
}

class _OrderStatusPieChartPainter extends CustomPainter {
  final double pending;
  final double accepted;
  final double dispatched;
  final double delivered;
  final double cancelled;

  _OrderStatusPieChartPainter({
    required this.pending,
    required this.accepted,
    required this.dispatched,
    required this.delivered,
    required this.cancelled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = pending + accepted + dispatched + delivered + cancelled;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    final paintBg = Paint()
      ..color = const Color(0xFFEFF4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - (strokeWidth / 2), paintBg);

    if (total == 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2));
    double startAngle = -math.pi / 2;

    void drawSegment(double value, Color color) {
      if (value <= 0) return;
      final sweep = (value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }

    drawSegment(pending, const Color(0xFFF59E0B));
    drawSegment(accepted, const Color(0xFF0284C7));
    drawSegment(dispatched, const Color(0xFF8B5CF6));
    drawSegment(delivered, const Color(0xFF10B981));
    drawSegment(cancelled, const Color(0xFFEF4444));
  }

  @override
  bool shouldRepaint(covariant _OrderStatusPieChartPainter oldDelegate) {
    return oldDelegate.pending != pending ||
        oldDelegate.accepted != accepted ||
        oldDelegate.dispatched != dispatched ||
        oldDelegate.delivered != delivered ||
        oldDelegate.cancelled != cancelled;
  }
}