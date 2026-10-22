import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';
import '../invoice_service.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  int _totalRevenue = 0;
  int _upiRevenue = 0;
  int _codRevenue = 0;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}?action=getallorders'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['status'] == 'SUCCESS') {
          final list = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
          int total = 0;
          int upi = 0;
          int cod = 0;

          for (var item in list) {
            final amt = (item['total_amount'] as num?)?.toInt() ?? 0;
            total += amt;
            final shipping = (item['shipping_address'] ?? '').toString();
            if (shipping.contains('UPI')) {
              upi += amt;
            } else {
              cod += amt;
            }
          }

          setState(() {
            _orders = list;
            _totalRevenue = total;
            _upiRevenue = upi;
            _codRevenue = cod;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _downloadInvoiceForOrder(Map<String, dynamic> ord) {
    final orderId = ord['order_id'] ?? 'ORD_001';
    final date = (ord['order_date'] ?? DateTime.now().toString()).toString().substring(0, 10);
    final totalAmount = (ord['total_amount'] as num?)?.toInt() ?? 0;
    final shipping = (ord['shipping_address'] ?? '').toString();
    final parts = shipping.split('|');

    final customerName = parts.isNotEmpty ? parts[0].trim() : 'Customer';
    final customerAddress = parts.length > 1 ? parts[1].trim() : shipping;
    final paymentMethod = parts.length > 2 ? parts[2].trim() : (shipping.contains('UPI') ? 'UPI Payment' : 'Cash On Delivery');

    final invoiceItems = [
      {
        'title': ord['shoe_name'] ?? 'StepUp Footwear',
        'selected_size': ord['size'] ?? '10',
        'quantity': (ord['quantity'] as num?)?.toInt() ?? 1,
        'price': totalAmount,
      }
    ];

    InvoiceService.generateAndDownloadInvoice(
      orderId: orderId,
      date: date,
      customerName: customerName,
      customerEmail: 'admin@stepup.com',
      customerPhone: 'N/A',
      customerAddress: customerAddress,
      paymentMethod: paymentMethod,
      items: invoiceItems,
      subtotal: totalAmount,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading PDF Invoice for #$orderId...'),
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
        title: const Text(
          'PAYMENTS & INVOICES',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: Color(0xFF0B1C30), fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0037B0)), onPressed: _fetchPayments),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0037B0)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Statistics Header
            Container(
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
                  BoxShadow(color: const Color(0xFF0037B0).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL REVENUE COLLECTED', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  Text('₹$_totalRevenue', style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('UPI Online', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('₹$_upiRevenue', style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cash On Delivery', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('₹$_codRevenue', style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const Text(
              'PAYMENT AUDIT LOGS & DOWNLOAD BILL',
              style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF434655), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),

            if (_orders.isEmpty)
              const Center(child: Text('No payment logs available', style: TextStyle(color: Color(0xFF747686))))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ord = _orders[index];
                  final isUpi = ord['shipping_address'].toString().contains('UPI');

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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUpi ? const Color(0xFFEFF4FF) : const Color(0xFFFFDBCA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(isUpi ? Icons.qr_code_rounded : Icons.money_rounded, color: isUpi ? const Color(0xFF0037B0) : const Color(0xFF9A4200), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ord['order_id'] ?? '', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0B1C30))),
                              const SizedBox(height: 2),
                              Text(isUpi ? 'UPI Verified' : 'Cash On Delivery', style: TextStyle(color: isUpi ? const Color(0xFF0037B0) : const Color(0xFF9A4200), fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text('₹${ord['total_amount']}', style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0B1C30))),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _downloadInvoiceForOrder(ord),
                          icon: const Icon(Icons.picture_as_pdf, size: 14, color: Colors.white),
                          label: const Text('BILL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0037B0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}