import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProductsFromSheet();
  }

  Future<void> _fetchProductsFromSheet() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}?action=getallproducts'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['status'] == 'SUCCESS') {
          setState(() {
            _products = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _deleteProduct(String shoeId) async {
    setState(() => _isLoading = true);
    try {
      await http.post(
        Uri.parse(ApiService.baseUrl),
        body: jsonEncode({'action': 'deleteproduct', 'shoe_id': shoeId}),
      );
      _fetchProductsFromSheet();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _openProductDialog({Map<String, dynamic>? item}) {
    final titleCtrl = TextEditingController(text: item != null ? item['title'] : '');
    final brandCtrl = TextEditingController(text: item != null ? item['brand'] : '');
    final priceCtrl = TextEditingController(text: item != null ? item['price'].toString() : '');
    final stockCtrl = TextEditingController(text: item != null ? item['stock_quantity'].toString() : '10');
    final imgCtrl = TextEditingController(text: item != null ? item['image_url'] : 'assets/Puma.jpg');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          item == null ? 'ADD NEW PRODUCT' : 'EDIT PRODUCT',
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B1C30)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Color(0xFF0B1C30)),
                decoration: const InputDecoration(labelText: 'Shoe Title', labelStyle: TextStyle(color: Color(0xFF747686))),
              ),
              TextField(
                controller: brandCtrl,
                style: const TextStyle(color: Color(0xFF0B1C30)),
                decoration: const InputDecoration(labelText: 'Brand (Puma, Nike...)', labelStyle: TextStyle(color: Color(0xFF747686))),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF0B1C30)),
                decoration: const InputDecoration(labelText: 'Price (₹)', labelStyle: TextStyle(color: Color(0xFF747686))),
              ),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF0B1C30)),
                decoration: const InputDecoration(labelText: 'Stock Quantity', labelStyle: TextStyle(color: Color(0xFF747686))),
              ),
              TextField(
                controller: imgCtrl,
                style: const TextStyle(color: Color(0xFF0B1C30)),
                decoration: const InputDecoration(labelText: 'Image Asset/URL', labelStyle: TextStyle(color: Color(0xFF747686))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF747686), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0037B0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await http.post(
                Uri.parse(ApiService.baseUrl),
                body: jsonEncode({
                  'action': 'saveproduct',
                  'shoe_id': item != null ? item['shoe_id'] : '',
                  'title': titleCtrl.text.trim(),
                  'brand': brandCtrl.text.trim(),
                  'price': priceCtrl.text.trim(),
                  'stock_quantity': stockCtrl.text.trim(),
                  'image_url': imgCtrl.text.trim(),
                }),
              );
              _fetchProductsFromSheet();
            },
            child: const Text('SAVE TO SHEET'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1C30), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CATALOG',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: Color(0xFF0B1C30), fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0037B0)), onPressed: _fetchProductsFromSheet),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0037B0),
        onPressed: () => _openProductDialog(),
        child: const Icon(Icons.add_box_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0037B0)))
          : _products.isEmpty
          ? const Center(child: Text('No products in Google Sheet catalog', style: TextStyle(color: Color(0xFF747686), fontWeight: FontWeight.bold)))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = _products[index];
          final isLocal = !(p['image_url'] ?? '').toString().startsWith('http');

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 65,
                    height: 65,
                    color: const Color(0xFFEFF4FF),
                    padding: const EdgeInsets.all(6),
                    child: isLocal
                        ? Image.asset(p['image_url'] ?? '', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                        : Image.network(p['image_url'] ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((p['brand'] ?? '').toString().toUpperCase(), style: const TextStyle(color: Color(0xFF0037B0), fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0B1C30))),
                      const SizedBox(height: 2),
                      Text('₹${p['price']} | Stock: ${p['stock_quantity']}', style: const TextStyle(color: Color(0xFF434655), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0037B0)), onPressed: () => _openProductDialog(item: p)),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent), onPressed: () => _deleteProduct(p['shoe_id'].toString())),
              ],
            ),
          );
        },
      ),
    );
  }
}