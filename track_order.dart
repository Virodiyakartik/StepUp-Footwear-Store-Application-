import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'invoice_service.dart';

class TrackOrderScreen extends StatefulWidget {
  final String? initialOrderId;
  final Map<String, dynamic>? currentUser;

  const TrackOrderScreen({
    super.key,
    this.initialOrderId,
    this.currentUser,
  });

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final TextEditingController _orderIdCtrl = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _searchedOrder;
  List<Map<String, dynamic>> _myRecentOrders = [];
  String? _errorMessage;

  final List<String> _steps = ['Pending', 'Accepted', 'Dispatched', 'Delivered'];

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderId != null && widget.initialOrderId!.isNotEmpty) {
      _orderIdCtrl.text = widget.initialOrderId!;
      _trackSpecificOrder(widget.initialOrderId!);
    } else {
      _loadMyOrdersFromSheet();
    }
  }

  @override
  void dispose() {
    _orderIdCtrl.dispose();
    super.dispose();
  }

  // Google Sheet માંથી બધા ઓર્ડર્સ ફેચ કરી ફિલ્ટર કરે છે
  Future<void> _loadMyOrdersFromSheet() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}?action=getallorders'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['status'] == 'SUCCESS') {
          final List list = decoded['data'] ?? [];
          final currentUserId = (widget.currentUser?['user_id'] ?? '').toString();

          List<Map<String, dynamic>> userOrders = [];
          for (var item in list) {
            if (currentUserId.isNotEmpty && item['user_id'].toString() == currentUserId) {
              userOrders.add(Map<String, dynamic>.from(item));
            }
          }

          if (mounted) {
            setState(() {
              _myRecentOrders = userOrders.reversed.toList();
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  // સ્પષ્ટ ઓર્ડર આઈડી ટ્રેક કરવા માટે
  Future<void> _trackSpecificOrder(String orderId) async {
    final cleanId = orderId.trim().toUpperCase();
    if (cleanId.isEmpty) return;

    // ૧૦ અક્ષરની લંબાઈ ચકાસણી (ORD_ + 6 Digits)
    if (cleanId.length != 10 || !cleanId.startsWith('ORD_')) {
      setState(() {
        _errorMessage = 'Order ID must be exactly 10 characters (e.g. ORD_502640)';
        _isLoading = false;
        _searchedOrder = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchedOrder = null;
    });

    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}?action=getallorders'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['status'] == 'SUCCESS') {
          final List list = decoded['data'] ?? [];
          final match = list.firstWhere(
                (item) => item['order_id'].toString().trim().toUpperCase() == cleanId,
            orElse: () => null,
          );

          if (mounted) {
            if (match != null) {
              setState(() {
                _searchedOrder = Map<String, dynamic>.from(match);
                _isLoading = false;
              });
              return;
            } else {
              setState(() {
                _errorMessage = 'No order found with ID: "$cleanId". Check your Order ID and try again.';
                _isLoading = false;
              });
              return;
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error while tracking order. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  int _getStepIndex(String status) {
    final s = status.toLowerCase();
    if (s.contains('deliver')) return 3;
    if (s.contains('dispatch')) return 2;
    if (s.contains('accept')) return 1;
    return 0; // Pending
  }

  Color _getStatusBadgeColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('cancel')) return const Color(0xFFEF4444);
    if (s.contains('deliver')) return const Color(0xFF10B981);
    if (s.contains('dispatch')) return const Color(0xFF8B5CF6);
    if (s.contains('accept') || s.contains('confirm')) return const Color(0xFF0037B0);
    return const Color(0xFFF59E0B);
  }

  void _downloadInvoice(Map<String, dynamic> ord) {
    final orderId = ord['order_id'] ?? 'ORD_001';
    final date = (ord['order_date'] ?? DateTime.now().toString()).toString().substring(0, 10);
    final totalAmount = (ord['total_amount'] as num?)?.toInt() ?? 0;
    final shipping = (ord['shipping_address'] ?? '').toString();
    final parts = shipping.split('|');

    final customerName = parts.isNotEmpty ? parts[0].trim() : (widget.currentUser?['name'] ?? 'Customer');
    final customerAddress = parts.length > 1 ? parts[1].trim() : shipping;
    final paymentMethod = parts.length > 2 ? parts[2].trim() : (shipping.contains('UPI') ? 'UPI Instant Pay' : 'Cash on Delivery (COD)');

    final invoiceItems = [
      {
        'title': ord['shoe_name'] ?? 'StepUp Sneaker',
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
        content: Text('Downloading Tax Invoice PDF for #$orderId...'),
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
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0037B0)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'TRACK SHIPMENT',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
                color: Color(0xFF0B1C30),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Order ID Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0037B0).withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Track By Order Number',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter your 10-digit order ID (e.g. ORD_502640)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF747686)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded, color: Color(0xFF0037B0), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _orderIdCtrl,
                                  maxLength: 10,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(
                                    color: Color(0xFF0B1C30),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Order ID (e.g. ORD_502640)',
                                    counterText: '',
                                    hintStyle: TextStyle(color: Color(0xFF747686), fontSize: 12),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onSubmitted: (val) => _trackSpecificOrder(val),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _trackSpecificOrder(_orderIdCtrl.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0037B0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('TRACK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // જો કોઈ ચોક્કસ ઓર્ડર શોધાયો હોય
            if (_searchedOrder != null) ...[
              _buildOrderTrackingCard(_searchedOrder!),
              const SizedBox(height: 24),
            ],

            // યુઝરના તાજેતરના ઓર્ડર્સ (Google Sheet)
            if (_myRecentOrders.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Recent Orders (Google Sheet)',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                  Text(
                    '${_myRecentOrders.length} orders',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0037B0)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myRecentOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ord = _myRecentOrders[index];
                  return _buildOrderTrackingCard(ord);
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTrackingCard(Map<String, dynamic> ord) {
    final orderId = (ord['order_id'] ?? '').toString();
    final status = (ord['order_status'] ?? 'Confirmed').toString();
    final isCancelled = status.toLowerCase().contains('cancel');
    final activeStep = _getStepIndex(status);
    final badgeColor = _getStatusBadgeColor(status);
    final isUpi = ord['shipping_address'].toString().contains('UPI');
    final date = (ord['order_date'] ?? DateTime.now().toString()).toString().substring(0, 10);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Order ID & Live Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                  Text('Placed on $date', style: const TextStyle(fontSize: 11, color: Color(0xFF747686))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Shoe Item Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.snowshoeing_rounded, color: Color(0xFF0037B0), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (ord['shoe_name'] ?? 'StepUp Kicks').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0B1C30)),
                      ),
                      Text(
                        'Size: UK ${ord['size'] ?? '7'} • Qty: ${ord['quantity'] ?? '1'}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF434655)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${ord['total_amount'] ?? '0'}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF0037B0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Stepper Timeline (Line & Titles 100% Symmetrical)
          if (isCancelled)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'This order was cancelled by Admin or User.',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ],
              ),
            )
          else ...[
            const Text(
              'Shipment Status Tracker',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(height: 16),

            // PERFECT ALIGNED STEPPER ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_steps.length, (idx) {
                final isDone = idx <= activeStep;

                return Expanded(
                  child: Column(
                    children: [
                      // Line - Circle - Line Row
                      Row(
                        children: [
                          // Left connecting line
                          Expanded(
                            child: Container(
                              height: 3,
                              color: idx == 0
                                  ? Colors.transparent
                                  : (activeStep >= idx ? const Color(0xFF0037B0) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          // Step Circle Avatar
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: isDone ? const Color(0xFF0037B0) : const Color(0xFFEFF4FF),
                            child: isDone
                                ? const Icon(Icons.check, size: 13, color: Colors.white)
                                : Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF747686),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          // Right connecting line
                          Expanded(
                            child: Container(
                              height: 3,
                              color: idx == _steps.length - 1
                                  ? Colors.transparent
                                  : (activeStep > idx ? const Color(0xFF0037B0) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Step Title (Centered directly under the circle)
                      Text(
                        _steps[idx],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
                          color: isDone ? const Color(0xFF0B1C30) : const Color(0xFF747686),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE2E8F0), height: 16),

          // Bottom Bar: Payment Mode & Download Bill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isUpi ? Icons.qr_code_rounded : Icons.money_rounded, size: 16, color: isUpi ? const Color(0xFF0037B0) : const Color(0xFF9A4200)),
                  const SizedBox(width: 6),
                  Text(
                    isUpi ? 'UPI Verified' : 'Cash on Delivery',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isUpi ? const Color(0xFF0037B0) : const Color(0xFF9A4200)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _downloadInvoice(ord),
                icon: const Icon(Icons.picture_as_pdf, size: 13, color: Color(0xFF0037B0)),
                label: const Text('DOWNLOAD INVOICE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0037B0))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0037B0), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}