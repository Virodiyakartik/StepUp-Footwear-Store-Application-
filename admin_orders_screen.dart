import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String _selectedFilter = 'All';

  final List<String> _statuses = ['Pending', 'Accepted', 'Dispatched', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}?action=getallorders'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['status'] == 'SUCCESS') {
          setState(() {
            _orders = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    // Optimistic UI update
    setState(() {
      final idx = _orders.indexWhere((o) => o['order_id'].toString() == orderId);
      if (idx >= 0) {
        _orders[idx]['order_status'] = newStatus;
      }
    });

    try {
      final res = await http.post(
        Uri.parse(ApiService.baseUrl),
        body: jsonEncode({
          'action': 'updateorderstatus',
          'order_id': orderId,
          'order_status': newStatus,
        }),
      );

      final decoded = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? 'Order status updated in Sheet!'),
            backgroundColor: _getStatusColor(newStatus),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      _fetchOrders();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF0284C7);
      case 'dispatched':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'All') return _orders;
    return _orders.where((o) => (o['order_status'] ?? 'Pending').toString().toLowerCase() == _selectedFilter.toLowerCase()).toList();
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
        title: const Text(
          'ORDER MANAGEMENT',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: Color(0xFF0B1C30), fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0037B0)), onPressed: _fetchOrders),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', ..._statuses].map((st) {
                final isSel = _selectedFilter == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSel,
                    label: Text(st),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF0B1C30),
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                    selectedColor: const Color(0xFF0037B0),
                    backgroundColor: const Color(0xFFEFF4FF),
                    onSelected: (_) => setState(() => _selectedFilter = st),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0037B0)))
                : _filteredOrders.isEmpty
                ? const Center(child: Text('No matching orders found.', style: TextStyle(color: Color(0xFF747686), fontWeight: FontWeight.bold)))
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ord = _filteredOrders[index];
                final String orderId = (ord['order_id'] ?? '').toString();
                final String currentStatus = (ord['order_status'] ?? 'Pending').toString();
                final Color statusColor = _getStatusColor(currentStatus);

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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            orderId,
                            style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF0037B0), fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentStatus.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shoe: ${ord['shoe_name']} (UK ${ord['size']}) | Qty: ${ord['quantity']}',
                        style: const TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ord['shipping_address']}',
                        style: const TextStyle(color: Color(0xFF434655), fontSize: 11.5, height: 1.3),
                      ),
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Order Total', style: TextStyle(fontSize: 10, color: Color(0xFF747686), fontWeight: FontWeight.bold)),
                              Text('₹${ord['total_amount']}', style: const TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0B1C30))),
                            ],
                          ),
                          // Change Status Action Button
                          PopupMenuButton<String>(
                            onSelected: (newStatus) => _updateStatus(orderId, newStatus),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            itemBuilder: (context) => _statuses.map((s) {
                              return PopupMenuItem(
                                value: s,
                                child: Row(
                                  children: [
                                    CircleAvatar(radius: 4, backgroundColor: _getStatusColor(s)),
                                    const SizedBox(width: 8),
                                    Text(s, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              );
                            }).toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: const [
                                  Text('Change Status', style: TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.w800, fontSize: 11)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, color: Color(0xFF0037B0), size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}