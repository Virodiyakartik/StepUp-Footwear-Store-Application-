import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'invoice_service.dart';
import 'shop.dart';

class NotificationsScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUser;

  const NotificationsScreen({super.key, this.currentUser});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadLiveNotifications();
  }

  Future<void> _loadLiveNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> list = [];

    // 1. ઓફર નોટિફિકેશન
    list.add({
      'type': 'offer',
      'title': '⚡ FLASH DROP OFFER: 40% OFF!',
      'body': 'Spring season exclusive coupon "SPRING40" is active. Tap to claim instant discount on retros & silhouettes.',
      'time': 'Just now',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFF59E0B),
      'action_label': 'SHOP NOW',
      'brand': null,
    });

    try {
      // 2. Google Sheet માંથી નવા શૂઝની તપાસ
      final pRes = await http.get(Uri.parse('${ApiService.baseUrl}?action=getallproducts'));
      if (pRes.statusCode == 200) {
        final pData = jsonDecode(pRes.body);
        if (pData['status'] == 'SUCCESS') {
          final List prods = pData['data'] ?? [];
          if (prods.isNotEmpty) {
            final latestShoe = prods.last;
            final brandName = (latestShoe['brand'] ?? '').toString().trim();
            list.add({
              'type': 'new_shoe',
              'title': '🔥 New Drop Added: ${latestShoe['title']}',
              'body': '$brandName release is now live in store for ₹${latestShoe['price']}. Limited deadstock units available.',
              'time': 'Recent drop',
              'icon': Icons.snowshoeing_rounded,
              'color': const Color(0xFF0037B0),
              'action_label': 'VIEW DROP',
              'brand': brandName.isNotEmpty ? brandName : null,
            });
          }
        }
      }

      // 3. Google Sheet માંથી યુઝરના ઓર્ડર અને કન્ફર્મેશન PDF
      final oRes = await http.get(Uri.parse('${ApiService.baseUrl}?action=getallorders'));
      if (oRes.statusCode == 200) {
        final oData = jsonDecode(oRes.body);
        if (oData['status'] == 'SUCCESS') {
          final List orders = oData['data'] ?? [];
          final currentUserId = (widget.currentUser?['user_id'] ?? '').toString();

          for (var ord in orders.reversed) {
            if (currentUserId.isNotEmpty && ord['user_id'].toString() == currentUserId) {
              final status = (ord['order_status'] ?? 'Confirmed').toString();
              list.add({
                'type': 'order',
                'title': '📦 Order #${ord['order_id']} is $status',
                'body': 'Item: ${ord['shoe_name']} (UK ${ord['size']}) | Total: ₹${ord['total_amount']}. Tap below to download official Tax Invoice PDF.',
                'time': (ord['order_date'] ?? '').toString().substring(0, 10),
                'icon': Icons.receipt_long_rounded,
                'color': const Color(0xFF10B981),
                'action_label': 'DOWNLOAD PDF BILL',
                'order_data': ord,
              });
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  void _downloadPdfBill(Map<String, dynamic> ord) {
    final orderId = ord['order_id'] ?? 'ORD_001';
    final date = (ord['order_date'] ?? DateTime.now().toString()).toString().substring(0, 10);
    final totalAmount = (ord['total_amount'] as num?)?.toInt() ?? 0;
    final shipping = (ord['shipping_address'] ?? '').toString();
    final parts = shipping.split('|');

    final customerName = parts.isNotEmpty ? parts[0].trim() : (widget.currentUser?['name'] ?? 'Customer');
    final customerAddress = parts.length > 1 ? parts[1].trim() : shipping;
    final paymentMethod = parts.length > 2 ? parts[2].trim() : (shipping.contains('UPI') ? 'UPI Instant Pay' : 'Cash on Delivery');

    final invoiceItems = [
      {
        'title': ord['shoe_name'] ?? 'StepUp Footwear',
        'selected_size': ord['size'] ?? '7',
        'quantity': (ord['quantity'] as num?)?.toInt() ?? 1,
        'price': totalAmount,
      }
    ];

    InvoiceService.generateAndDownloadInvoice(
      orderId: orderId,
      date: date,
      customerName: customerName,
      customerEmail: widget.currentUser?['email'] ?? 'customer@stepup.com',
      customerPhone: widget.currentUser?['phone_number'] ?? 'N/A',
      customerAddress: customerAddress,
      paymentMethod: paymentMethod,
      items: invoiceItems,
      subtotal: totalAmount,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading Invoice PDF for #$orderId...'),
        backgroundColor: const Color(0xFF0037B0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1C30), size: 18),
          onPressed: () => Navigator.pop(context),
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
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'NOTIFICATIONS',
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0037B0)),
            onPressed: _loadLiveNotifications,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0037B0)))
          : _notifications.isEmpty
          ? const Center(child: Text('No new notifications', style: TextStyle(color: Color(0xFF747686), fontWeight: FontWeight.bold)))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          final Color color = item['color'];

          return Container(
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item['icon'], color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['title'],
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF0B1C30),
                        ),
                      ),
                    ),
                    Text(
                      item['time'],
                      style: const TextStyle(color: Color(0xFF747686), fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['body'],
                  style: const TextStyle(color: Color(0xFF434655), fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (item['type'] == 'order' && item['order_data'] != null) {
                        _downloadPdfBill(item['order_data']);
                      } else if (item['type'] == 'offer' || item['type'] == 'new_shoe') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShopScreen(
                              wishlistedIds: const {},
                              onAddToCart: (_) {},
                              onToggleWishlist: (_) {},
                              initialBrand: item['brand'],
                              userId: (widget.currentUser?['user_id'] ?? 'GUEST').toString(),
                              userName: (widget.currentUser?['name'] ?? 'Customer').toString(),
                              currentUser: widget.currentUser,
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      item['type'] == 'order' ? Icons.picture_as_pdf_rounded : Icons.arrow_forward_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      item['action_label'],
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}