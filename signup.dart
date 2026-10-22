import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _selectedGender = 'Male';
  String _selectedCountryCode = '+91';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Auto-Redirecting 3D Popup
  void _show3dRegisteredDialog({required String userName, required VoidCallback onAutoRedirect}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'RegisterDialog',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curvedValue = Curves.easeOutBack.transform(anim.value);
        return Transform.scale(
          scale: curvedValue,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 330,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.18),
                      blurRadius: 36,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF047857)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 44),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ACCOUNT CREATED!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Color(0xFF0B1C30),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome to StepUp Club, $userName!\nRedirecting to Sign In...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF434655),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      onAutoRedirect();
    });
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final userName = _nameController.text.trim();
      final result = await ApiService.registerUser(
        name: userName,
        email: _emailController.text.trim(),
        phone: '$_selectedCountryCode ${_phoneController.text.trim()}',
        gender: _selectedGender ?? 'Male',
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['status'] == 'SUCCESS') {
        _show3dRegisteredDialog(
          userName: userName,
          onAutoRedirect: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Registration failed!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'BECOME A MEMBER',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: Color(0xFF0B1C30),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0037B0).withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'STEPUP CLUB',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Get 15% off your first drop & free express shipping.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF434655),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Color(0xFF0B1C30), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'FULL NAME',
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF747686),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0037B0), size: 18),
                        filled: true,
                        fillColor: const Color(0xFFEFF4FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                        ),
                      ),
                      validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Enter your full name' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Color(0xFF0B1C30), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'EMAIL ADDRESS',
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF747686),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0037B0), size: 18),
                        filled: true,
                        fillColor: const Color(0xFFEFF4FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                        ),
                      ),
                      validator: (value) =>
                      (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.bold),
                              items: ['+91', '+1', '+44', '+971'].map((val) {
                                return DropdownMenuItem(
                                  value: val,
                                  child: Text(val, style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 13, fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedCountryCode = val!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(color: Color(0xFF0B1C30), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'PHONE NUMBER',
                              counterText: '',
                              labelStyle: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF747686),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0037B0), size: 18),
                              filled: true,
                              fillColor: const Color(0xFFEFF4FF),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return 'Enter phone number';
                              if (text.length != 10) return 'Must be exactly 10 digits';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text(
                          'GENDER:',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF434655),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Radio<String>(
                          value: 'Male',
                          groupValue: _selectedGender,
                          activeColor: const Color(0xFF0037B0),
                          onChanged: (val) => setState(() => _selectedGender = val),
                        ),
                        const Text('Male', style: TextStyle(color: Color(0xFF0B1C30), fontSize: 13, fontWeight: FontWeight.w600)),
                        Radio<String>(
                          value: 'Female',
                          groupValue: _selectedGender,
                          activeColor: const Color(0xFF0037B0),
                          onChanged: (val) => setState(() => _selectedGender = val),
                        ),
                        const Text('Female', style: TextStyle(color: Color(0xFF0B1C30), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Color(0xFF0B1C30), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'PASSWORD',
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF747686),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0037B0), size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF747686),
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFEFF4FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                        ),
                      ),
                      validator: (value) => (value == null || value.length < 6) ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Color(0xFF0B1C30), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'CONFIRM PASSWORD',
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF747686),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0037B0), size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF747686),
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFEFF4FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                        ),
                      ),
                      validator: (value) => (value != _passwordController.text) ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0037B0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                        shadowColor: const Color(0xFF0037B0).withValues(alpha: 0.35),
                      ),
                      onPressed: _isLoading ? null : _handleSignup,
                      child: _isLoading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text(
                        'CREATE MEMBER ACCOUNT',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already a member?',
                          style: TextStyle(fontFamily: 'Inter', color: Color(0xFF434655), fontSize: 12.5),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'SIGN IN',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Color(0xFF0037B0),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}