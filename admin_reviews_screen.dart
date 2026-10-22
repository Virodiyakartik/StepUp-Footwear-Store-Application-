import 'package:flutter/material.dart';
import '../api_service.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviewsFromSheet();
  }

  Future<void> _fetchReviewsFromSheet() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getReviews('');
    if (mounted) {
      setState(() {
        _reviews = data;
        _isLoading = false;
      });
    }
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
          'REVIEWS & FEEDBACK',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: Color(0xFF0B1C30), fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0037B0)), onPressed: _fetchReviewsFromSheet),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0037B0)))
          : _reviews.isEmpty
          ? const Center(child: Text('No reviews found in Google Sheet', style: TextStyle(color: Color(0xFF747686), fontWeight: FontWeight.bold)))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final rev = _reviews[index];
          final ratingVal = (rev['rating'] as num?)?.toInt() ?? 5;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
                    Text(rev['user_name'] ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0B1C30))),
                    Row(
                      children: List.generate(
                        ratingVal,
                            (i) => const Icon(Icons.star, color: Colors.amber, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Target Shoe: ${rev['shoe_id']}', style: const TextStyle(color: Color(0xFF0037B0), fontSize: 10.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('"${rev['review_text'] ?? ''}"', style: const TextStyle(color: Color(0xFF434655), fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          );
        },
      ),
    );
  }
}