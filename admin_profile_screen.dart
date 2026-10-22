import 'package:flutter/material.dart';

class AdminProfileScreen extends StatelessWidget {
  final String adminName;
  final String email;
  final String phone;
  final String companyName;
  final String role;
  final String adminId;

  const AdminProfileScreen({
    super.key,
    this.adminName = 'Kartik Virodiya',
    this.email = 'kartikvirodiya2907@gmail.com',
    this.phone = '+91 6355688250',
    this.companyName = 'StepUp Footwear India Ltd.',
    this.role = 'Super Administrator',
    this.adminId = 'ADM_9898012345',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1C30), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ADMIN PROFILE',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.1,
            color: Color(0xFF0B1C30),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          children: [
            // Admin Avatar & Main Badge
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF0037B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0037B0).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              adminName,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xFF0037B0),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Info Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OFFICIAL CREDENTIALS',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF747686),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildProfileRow(Icons.badge_outlined, 'Admin ID', adminId, isHighlight: true),
                  const Divider(color: Color(0xFFF1F5F9), height: 18),
                  _buildProfileRow(Icons.business_rounded, 'Company Name', companyName),
                  const Divider(color: Color(0xFFF1F5F9), height: 18),
                  _buildProfileRow(Icons.email_outlined, 'Official Email', email),
                  const Divider(color: Color(0xFFF1F5F9), height: 18),
                  _buildProfileRow(Icons.phone_outlined, 'Mobile Number', phone),
                  const Divider(color: Color(0xFFF1F5F9), height: 18),
                  _buildProfileRow(Icons.security_rounded, 'Authorization', 'Full Google Sheet Access (RW)'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // System Security & Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF0037B0).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0037B0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Google Sheet Synced',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF0B1C30),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'All database operations are actively authenticated.',
                          style: TextStyle(color: Color(0xFF434655), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Action
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF0037B0)),
                label: const Text(
                  'BACK TO DASHBOARD',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.8,
                    color: Color(0xFF0037B0),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0037B0), width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF0037B0)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF747686), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: isHighlight ? 'Outfit' : 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isHighlight ? const Color(0xFF0037B0) : const Color(0xFF0B1C30),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}