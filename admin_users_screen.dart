import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsersFromSheet();
  }

  Future<void> _fetchUsersFromSheet() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}?action=getallusers'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['status'] == 'SUCCESS') {
          setState(() {
            _users = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);
    try {
      await http.post(
        Uri.parse(ApiService.baseUrl),
        body: jsonEncode({'action': 'deleteuser', 'user_id': userId}),
      );
      _fetchUsersFromSheet();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _openAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'Customer';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'ADD USER TO SHEET',
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B1C30)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Color(0xFF0B1C30)),
                  decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: Color(0xFF747686))),
                ),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFF0B1C30)),
                  decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: Color(0xFF747686))),
                ),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Color(0xFF0B1C30)),
                  decoration: const InputDecoration(
                    labelText: 'Phone (10 Digits)',
                    counterText: '',
                    prefixText: '+91 ',
                    labelStyle: TextStyle(color: Color(0xFF747686)),
                  ),
                ),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Color(0xFF0B1C30)),
                  decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Color(0xFF747686))),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Role:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF434655))),
                    DropdownButton<String>(
                      value: selectedRole,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.bold),
                      items: ['Customer', 'Member', 'Admin', 'Super Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) => setDialogState(() => selectedRole = v!),
                    ),
                  ],
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
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || phoneCtrl.text.trim().length != 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid name, email & 10-digit phone!'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                await ApiService.registerUser(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: '+91 ${phoneCtrl.text.trim()}',
                  gender: 'Male',
                  password: passCtrl.text.trim(),
                );
                _fetchUsersFromSheet();
              },
              child: const Text('ADD USER'),
            ),
          ],
        ),
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
          'USERS DIRECTORY',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: Color(0xFF0B1C30), fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0037B0)), onPressed: _fetchUsersFromSheet),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0037B0),
        onPressed: _openAddUserDialog,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0037B0)))
          : _users.isEmpty
          ? const Center(child: Text('No users found in Google Sheet', style: TextStyle(color: Color(0xFF747686), fontWeight: FontWeight.bold)))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final u = _users[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEFF4FF),
                child: Text(
                  (u['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.bold),
                ),
              ),
              title: Text((u['name'] ?? 'Member').toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B1C30))),
              subtitle: Text('${u['email']} • +91 ${u['phone_number'] ?? ''}', style: const TextStyle(color: Color(0xFF747686), fontSize: 11.5)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(6)),
                    child: Text((u['role'] ?? 'Customer').toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0037B0))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () => _deleteUser(u['user_id'].toString()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}