import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'invoice_service.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic>? currentUser;

  const CartScreen({
    super.key,
    required this.cartItems,
    this.currentUser,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<Map<String, dynamic>> _items;
  bool _isCheckoutView = false;
  bool _isPlacingOrder = false;

  final _promoCtrl = TextEditingController(text: 'SPRING40');
  bool _promoApplied = true;
  final int _discountAmount = 35;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _selectedState = 'Gujarat';
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

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(widget.cartItems);
    if (widget.currentUser != null) {
      final names = (widget.currentUser!['name'] ?? '').toString().split(' ');
      _firstNameCtrl.text = names.isNotEmpty ? names.first : '';
      _lastNameCtrl.text = names.length > 1 ? names.sublist(1).join(' ') : '';
      _emailCtrl.text = (widget.currentUser!['email'] ?? '').toString();

      String rawPhone = (widget.currentUser!['phone_number'] ?? widget.currentUser!['phone'] ?? '')
          .toString()
          .replaceAll('+', '')
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .trim();
      if (rawPhone.startsWith('91') && rawPhone.length > 10) {
        rawPhone = rawPhone.substring(2);
      }
      _phoneCtrl.text = rawPhone;
    }
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
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
    super.dispose();
  }

  int get _subtotal {
    int sum = 0;
    for (var item in _items) {
      final int price = (item['price'] as num?)?.toInt() ?? 0;
      final int qty = (item['quantity'] as num?)?.toInt() ?? 1;
      sum += (price * qty);
    }
    return sum;
  }

  int get _finalTotal {
    int total = _subtotal;
    if (_promoApplied && total > _discountAmount) {
      total -= _discountAmount;
    }
    return total;
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final currentQty = (_items[index]['quantity'] as num?)?.toInt() ?? 1;
      final newQty = currentQty + delta;
      if (newQty > 0) {
        _items[index]['quantity'] = newQty;
      } else {
        _removeItem(index);
      }
    });
  }

  void _removeItem(int index) {
    final removed = _items[index];
    final userId = (widget.currentUser?['user_id'] ?? 'GUEST').toString();
    final shoeId = (removed['id'] ?? removed['shoe_id'] ?? '').toString();
    final size = (removed['selected_size'] ?? removed['size'] ?? '7').toString();

    ApiService.removeFromCart(userId: userId, shoeId: shoeId, size: size);

    setState(() {
      _items.removeAt(index);
      if (_items.isEmpty) _isCheckoutView = false;
    });
  }

  Future<void> _placeOrder() async {
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

    if (_paymentMethod == 'UPI') {
      if (_upiIdCtrl.text.trim().isEmpty || _upiRefCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your UPI ID and Transaction Reference (UTR)!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isPlacingOrder = true);

    final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final customerName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
    final fullAddress =
        '${_address1Ctrl.text.trim()}, ${_address2Ctrl.text.trim().isNotEmpty ? '${_address2Ctrl.text.trim()}, ' : ''}${_cityCtrl.text.trim()}, $_selectedState - ${_pinCtrl.text.trim()} (Phone: $phoneText)';
    final userId = (widget.currentUser?['user_id'] ?? 'GUEST').toString();

    final shoeNames = _items.map((e) => (e['title'] ?? e['shoe_name'] ?? 'Shoe').toString()).join(', ');
    final shoeIds = _items.map((e) => (e['id'] ?? e['shoe_id'] ?? '').toString()).join(', ');
    final sizes = _items.map((e) => (e['selected_size'] ?? e['size'] ?? '7').toString()).join(', ');
    final totalQty = _items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1));
    final totalAmount = _finalTotal;

    final invoiceSnapshot = List<Map<String, dynamic>>.from(_items);
    final orderDate = DateTime.now().toString().substring(0, 10);

    final paymentDetails = _paymentMethod == 'UPI'
        ? 'UPI [Sender: ${_upiIdCtrl.text.trim()} | UTR: ${_upiRefCtrl.text.trim()}]'
        : 'Cash on Delivery (COD)';

    final res = await ApiService.placeOrder(
      orderId: orderId,
      userId: userId,
      shoeId: shoeIds,
      shoeName: shoeNames,
      size: sizes,
      quantity: totalQty,
      totalAmount: totalAmount,
      shippingAddress: '$customerName | $fullAddress | Pay: $paymentDetails',
      orderStatus: 'Confirmed',
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    setState(() {
      _items.clear();
      _isCheckoutView = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF0037B0), size: 24),
            SizedBox(width: 8),
            Text(
              'Order Confirmed!',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B1C30),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: #$orderId\n'
                  'Recipient: $customerName\n'
                  'Total Amount: ₹$totalAmount\n'
                  'Payment Mode: $paymentDetails\n\n'
                  '${res['status'] == 'SUCCESS' ? '✓ Saved to Google Sheet Orders table!' : 'Order recorded locally.'}',
              style: const TextStyle(color: Color(0xFF434655), fontSize: 13, height: 1.4),
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
                    items: invoiceSnapshot,
                    subtotal: totalAmount,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                label: const Text(
                  'DOWNLOAD INVOICE (PDF)',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0037B0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, _items);
            },
            child: const Text('OKAY', style: TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.bold)),
          ),
        ],
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
        toolbarHeight: 65,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1C30), size: 18),
          onPressed: () {
            if (_isCheckoutView) {
              setState(() => _isCheckoutView = false);
            } else {
              Navigator.pop(context, _items);
            }
          },
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
            const Text(
              'STEPUP',
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
        centerTitle: false,
        actions: [
          Center(
            child: Text(
              _isCheckoutView ? 'Checkout' : 'Cart (${_items.length})',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: Color(0xFF0B1C30),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _items.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: _isCheckoutView ? _buildShippingView() : _buildCartView(),
      ),
    );
  }

  Widget _buildCartView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'My Shopping Bag',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B1C30),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_items.length} items',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0037B0)),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => setState(() => _items.clear()),
              child: Row(
                children: const [
                  Icon(Icons.delete_sweep_outlined, size: 16, color: Color(0xFF747686)),
                  SizedBox(width: 3),
                  Text('Clear all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF747686))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Unlocked Perk Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0037B0), Color(0xFF1D4ED8)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0037B0).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('UNLOCKED PERK •', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Free Express Delivery Activated!', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                    Text('Dispatches from hub within 24 hours.', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Items List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _items[index];
            final qty = (item['quantity'] as num?)?.toInt() ?? 1;
            final isLocal = !(item['image_url'] ?? '').toString().startsWith('http');

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 85,
                      height: 85,
                      color: const Color(0xFFEFF4FF),
                      padding: const EdgeInsets.all(6),
                      child: isLocal
                          ? Image.asset(item['image_url'] ?? 'assets/Nikw.jpg', fit: BoxFit.contain)
                          : Image.network(
                        item['image_url'] ?? '',
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['brand'] ?? 'Performance Elite',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF747686)),
                            ),
                            GestureDetector(
                              onTap: () => _removeItem(index),
                              child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF747686)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (item['title'] ?? item['shoe_name'] ?? 'Shoe Name').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF0B1C30),
                          ),
                        ),
                        Text(
                          'Size: UK ${item['selected_size'] ?? item['size'] ?? '7'}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF434655)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${item['price']}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF0B1C30),
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _updateQuantity(index, -1),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.remove, size: 14, color: Color(0xFF0037B0)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '$qty',
                                    style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0B1C30)),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _updateQuantity(index, 1),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(color: const Color(0xFF0037B0), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // Promotions & Vouchers Box
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Promotions & Vouchers', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0B1C30))),
            Icon(Icons.local_offer_outlined, size: 16, color: Color(0xFF747686)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(22)),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoCtrl,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                      ),
                    ),
                    const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFF747686)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => setState(() => _promoApplied = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B1C30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 0,
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        if (_promoApplied) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFFDBCA), borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.verified_outlined, size: 14, color: Color(0xFF9A4200)),
                    SizedBox(width: 6),
                    Text('SPRING40 applied (-₹35)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF9A4200))),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _promoApplied = false),
                  child: const Icon(Icons.close, size: 14, color: Color(0xFF9A4200)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Order Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Summary', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0B1C30))),
              const SizedBox(height: 12),
              _summaryLine('Subtotal', '₹$_subtotal'),
              if (_promoApplied)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Discount (Promo)', style: TextStyle(fontSize: 12, color: Color(0xFF747686))),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFFFDBCA), borderRadius: BorderRadius.circular(4)),
                          child: const Text('SPRING40', style: TextStyle(fontSize: 9, color: Color(0xFF9A4200), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Text('-₹35', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF9A4200))),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Estimated Shipping', style: TextStyle(fontSize: 12, color: Color(0xFF747686))),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Active', style: TextStyle(fontSize: 9, color: Color(0xFF0037B0), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Text('FREE', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Total Amount', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0B1C30))),
                      Text('Includes GST & taxes', style: TextStyle(fontSize: 10, color: Color(0xFF747686))),
                    ],
                  ),
                  Text('₹$_finalTotal', style: const TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0037B0))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Checkout Button Bottom Bar
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF747686))),
                Text('₹$_finalTotal', style: const TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0B1C30))),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isCheckoutView = true),
                  icon: const Text('Proceed to Checkout', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  label: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0037B0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildShippingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isCheckoutView = false),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFFEFF4FF),
                child: Icon(Icons.arrow_back, size: 14, color: Color(0xFF0037B0)),
              ),
              SizedBox(width: 8),
              Text(
                'BACK TO CART',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xFF0B1C30),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SHIPPING & CONTACT',
                style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF0B1C30), fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildFormField('First Name *', _firstNameCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFormField('Last Name *', _lastNameCtrl)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(flex: 5, child: _buildFormField('Email *', _emailCtrl, keyboard: TextInputType.emailAddress)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 12.5, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'PHONE (10 Digits) *',
                        counterText: '',
                        labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11, fontWeight: FontWeight.bold),
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: const Color(0xFFEFF4FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFormField('PIN Code *', _pinCtrl, keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _buildFormField('Address Line 1 *', _address1Ctrl, icon: Icons.search),
              const SizedBox(height: 12),
              _buildFormField('Address Line 2 (Optional)', _address2Ctrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(flex: 5, child: _buildFormField('City *', _cityCtrl)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedState,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 12, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 18),
              const Text('PAYMENT METHOD', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF0B1C30), fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 6),
              RadioListTile<String>(
                value: 'COD',
                groupValue: _paymentMethod,
                title: const Text('Cash on Delivery (COD)', style: TextStyle(color: Color(0xFF0B1C30), fontSize: 12.5, fontWeight: FontWeight.bold)),
                subtitle: const Text('Pay with cash when order arrives at doorstep', style: TextStyle(color: Color(0xFF747686), fontSize: 10.5)),
                activeColor: const Color(0xFF0037B0),
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              RadioListTile<String>(
                value: 'UPI',
                groupValue: _paymentMethod,
                title: const Text('UPI Instant Pay (Google Pay / PhonePe / Paytm / BHIM)', style: TextStyle(color: Color(0xFF0B1C30), fontSize: 12.5, fontWeight: FontWeight.bold)),
                subtitle: const Text('Direct payment with Transaction ID / UTR verification', style: TextStyle(color: Color(0xFF747686), fontSize: 10.5)),
                activeColor: const Color(0xFF0037B0),
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),

              if (_paymentMethod == 'UPI') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0037B0).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.qr_code_scanner, color: Color(0xFF0037B0), size: 18),
                          SizedBox(width: 8),
                          Text('STEPUP OFFICIAL UPI TRANSFER', style: TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.w900, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('UPI ID: stepup@okhdfcbank', style: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.w900, fontSize: 12)),
                            Text('VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 9.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Transfer total amount via your UPI App, then enter payment details below for verification:', style: TextStyle(color: Color(0xFF434655), fontSize: 10.5)),
                      const SizedBox(height: 12),
                      _buildFormField('Your UPI ID (e.g. name@okaxis) *', _upiIdCtrl),
                      const SizedBox(height: 10),
                      _buildFormField('12-Digit UPI Ref / UTR No. *', _upiRefCtrl, keyboard: TextInputType.number),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0037B0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _isPlacingOrder
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                    _paymentMethod == 'UPI' ? 'VERIFY UPI & CONFIRM ORDER' : 'PLACE ORDER (COD)',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.1),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {TextInputType? keyboard, IconData? icon}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 12.5, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11, fontWeight: FontWeight.bold),
        suffixIcon: icon != null ? Icon(icon, color: const Color(0xFF434655), size: 16) : null,
        filled: true,
        fillColor: const Color(0xFFEFF4FF),
        isDense: true,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF747686))),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0B1C30))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFEFF4FF), shape: BoxShape.circle),
            child: const Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFF0037B0)),
          ),
          const SizedBox(height: 18),
          const Text(
            'YOUR BAG IS EMPTY',
            style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF0B1C30), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0037B0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: () => Navigator.pop(context, _items),
            child: const Text('START SHOPPING', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}