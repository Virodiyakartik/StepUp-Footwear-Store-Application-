import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'index.dart';
import 'api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = Map<String, dynamic>.from(widget.user);
  }

  String _getSafeValue(dynamic val, {String fallback = 'N/A'}) {
    if (val == null) return fallback;
    final str = val.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  String _formatPhone10Digits(dynamic val) {
    if (val == null) return '';
    String p = val.toString().replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '').trim();
    if (p.startsWith('91') && p.length > 10) {
      p = p.substring(2);
    }
    return p;
  }

  // 1. EDIT PROFILE DIALOG
  void _openEditProfileDialog() {
    final currentName = _getSafeValue(_currentUser['name'], fallback: '');
    final currentPhone = _formatPhone10Digits(_currentUser['phone_number'] ?? _currentUser['phone']);

    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);

    String rawGender = _getSafeValue(_currentUser['gender'], fallback: 'Male');
    String selectedGender = rawGender.toLowerCase() == 'female' ? 'Female' : 'Male';

    final formKey = GlobalKey<FormState>();
    String? dialogError;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: const Text(
            'EDIT PROFILE',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF0B1C30),
              letterSpacing: 1.0,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dialogError!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Color(0xFF0B1C30), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'FULL NAME',
                      labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11, fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: const Color(0xFFEFF4FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Color(0xFF0B1C30), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'PHONE NUMBER',
                      counterText: '',
                      labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11, fontWeight: FontWeight.w700),
                      prefixText: '+91 ',
                      prefixStyle: const TextStyle(color: Color(0xFF0037B0), fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: const Color(0xFFEFF4FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      final clean = (v ?? '').trim();
                      if (clean.isEmpty || clean.length != 10) {
                        return 'Enter 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'GENDER',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF434655),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Male',
                        groupValue: selectedGender,
                        activeColor: const Color(0xFF0037B0),
                        onChanged: (val) => setDialogState(() => selectedGender = val!),
                      ),
                      const Text('Male', style: TextStyle(color: Color(0xFF0B1C30), fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Radio<String>(
                        value: 'Female',
                        groupValue: selectedGender,
                        activeColor: const Color(0xFF0037B0),
                        onChanged: (val) => setDialogState(() => selectedGender = val!),
                      ),
                      const Text('Female', style: TextStyle(color: Color(0xFF0B1C30), fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
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
              onPressed: isSaving
                  ? null
                  : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() {
                    isSaving = true;
                    dialogError = null;
                  });

                  final cleanPhone = phoneController.text.trim();

                  final res = await ApiService.updateProfile(
                    userId: _currentUser['user_id'].toString(),
                    name: nameController.text.trim(),
                    phone: cleanPhone,
                    gender: selectedGender,
                  );

                  if (!mounted) return;

                  if (res['status'] == 'SUCCESS') {
                    Navigator.pop(ctx);
                    setState(() {
                      _currentUser['name'] = nameController.text.trim();
                      _currentUser['phone_number'] = cleanPhone;
                      _currentUser['phone'] = cleanPhone;
                      _currentUser['gender'] = selectedGender;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                        backgroundColor: Color(0xFF0037B0),
                      ),
                    );
                  } else {
                    setDialogState(() {
                      isSaving = false;
                      dialogError = res['message'] ?? 'Failed to update profile!';
                    });
                  }
                }
              },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  // 2. CHANGE PASSWORD DIALOG
  void _openChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? dialogError;
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: const Text(
            'CHANGE PASSWORD',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF0B1C30),
              letterSpacing: 1.0,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dialogError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dialogError!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  TextFormField(
                    controller: oldPassController,
                    obscureText: true,
                    style: const TextStyle(color: Color(0xFF0B1C30), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'CURRENT PASSWORD',
                      labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11, fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: const Color(0xFFEFF4FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openForgotPasswordDialog();
                      },
                      child: const Text(
                        'Forgot Password? Reset via Email OTP',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF0037B0),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassController,
                    obscureText: true,
                    style: const TextStyle(color: Color(0xFF0B1C30), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'NEW PASSWORD',
                      labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11, fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: const Color(0xFFEFF4FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: true,
                    style: const TextStyle(color: Color(0xFF0B1C30), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'CONFIRM NEW PASSWORD',
                      labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11, fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: const Color(0xFFEFF4FF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm password';
                      if (v != newPassController.text) return 'Passwords do not match!';
                      return null;
                    },
                  ),
                ],
              ),
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
              onPressed: isUpdating
                  ? null
                  : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() {
                    isUpdating = true;
                    dialogError = null;
                  });

                  final res = await ApiService.changePassword(
                    userId: _currentUser['user_id'].toString(),
                    oldPassword: oldPassController.text.trim(),
                    newPassword: newPassController.text.trim(),
                  );

                  if (!mounted) return;

                  if (res['status'] == 'SUCCESS') {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password updated successfully!'),
                        backgroundColor: Color(0xFF0037B0),
                      ),
                    );
                  } else {
                    setDialogState(() {
                      isUpdating = false;
                      dialogError = res['message'] ?? 'Current password is incorrect!';
                    });
                  }
                }
              },
              child: isUpdating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('UPDATE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  // 3. RESET PASSWORD VIA EMAIL OTP
  void _openForgotPasswordDialog() {
    int step = 1;
    String generatedOtp = '';
    bool isSendingOtp = false;
    bool isResetting = false;
    String? dialogError;

    final otpController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final stepFormKey = GlobalKey<FormState>();

    final email = _getSafeValue(_currentUser['email'], fallback: '');
    final userName = _getSafeValue(_currentUser['name'], fallback: 'Customer');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> generateAndSendEmailOtp() async {
            if (email.isEmpty || email == 'N/A') {
              setDialogState(() => dialogError = 'No registered email found for this account!');
              return;
            }

            final random = Random();
            generatedOtp = (100000 + random.nextInt(900000)).toString();

            setDialogState(() {
              isSendingOtp = true;
              dialogError = null;
            });

            final res = await ApiService.sendOtp(
              type: 'Email',
              target: email,
              otp: generatedOtp,
              name: userName,
            );

            setDialogState(() => isSendingOtp = false);

            if (res['status'] == 'SUCCESS') {
              setDialogState(() {
                step = 2;
                dialogError = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('OTP sent to $email. Please check Inbox/Spam!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            } else {
              setDialogState(() {
                dialogError = res['message'] ?? 'Failed to send OTP to email.';
              });
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            title: Row(
              children: [
                const Icon(Icons.email_outlined, color: Color(0xFF0037B0), size: 24),
                const SizedBox(width: 8),
                Text(
                  step == 1
                      ? 'EMAIL VERIFICATION'
                      : (step == 2 ? 'ENTER EMAIL OTP' : 'SET NEW PASSWORD'),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0B1C30),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Form(
                  key: stepFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dialogError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dialogError!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (step == 1) ...[
                        const Text(
                          'We will send a 6-digit verification code to your registered email address:',
                          style: TextStyle(color: Color(0xFF434655), fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF0037B0).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mark_email_read, color: Color(0xFF0037B0), size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Registered Email', style: TextStyle(color: Color(0xFF747686), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      email.isNotEmpty ? email : 'No email found',
                                      style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 13.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (step == 2) ...[
                        Text(
                          'Enter the 6-digit verification code sent to:\n$email',
                          style: const TextStyle(color: Color(0xFF434655), fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF0037B0), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '• • • • • •',
                            hintStyle: const TextStyle(color: Color(0xFFC4C5D7), letterSpacing: 4),
                            filled: true,
                            fillColor: const Color(0xFFEFF4FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length != 6) return 'Enter full 6-digit OTP';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: isSendingOtp ? null : () => generateAndSendEmailOtp(),
                            icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF0037B0)),
                            label: const Text('Resend OTP', style: TextStyle(color: Color(0xFF0037B0), fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                      if (step == 3) ...[
                        const Text(
                          'Email verified successfully! Set your new password.',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: newPassController,
                          obscureText: true,
                          style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'NEW PASSWORD',
                            labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11, fontWeight: FontWeight.w700),
                            filled: true,
                            fillColor: const Color(0xFFEFF4FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirmPassController,
                          obscureText: true,
                          style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'CONFIRM NEW PASSWORD',
                            labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11, fontWeight: FontWeight.w700),
                            filled: true,
                            fillColor: const Color(0xFFEFF4FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          validator: (v) => (v != newPassController.text) ? 'Passwords do not match' : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL', style: TextStyle(color: Color(0xFF747686), fontWeight: FontWeight.bold)),
              ),
              if (step == 1)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0037B0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isSendingOtp ? null : () => generateAndSendEmailOtp(),
                  child: isSendingOtp
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SEND OTP TO EMAIL', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              if (step == 2)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0037B0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (stepFormKey.currentState!.validate()) {
                      if (otpController.text.trim() != generatedOtp) {
                        setDialogState(() {
                          dialogError = 'Invalid OTP code! Please check your email inbox/spam.';
                        });
                        return;
                      }
                      setDialogState(() {
                        step = 3;
                        dialogError = null;
                      });
                    }
                  },
                  child: const Text('VERIFY OTP', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              if (step == 3)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isResetting
                      ? null
                      : () async {
                    if (stepFormKey.currentState!.validate()) {
                      setDialogState(() {
                        isResetting = true;
                        dialogError = null;
                      });

                      final res = await ApiService.changePassword(
                        userId: _currentUser['user_id'].toString(),
                        oldPassword: '',
                        newPassword: newPassController.text.trim(),
                      );

                      if (!mounted) return;

                      if (res['status'] == 'SUCCESS') {
                        Navigator.pop(ctx);
                        _currentUser['password'] = newPassController.text.trim();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset successfully via Email OTP!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          isResetting = false;
                          dialogError = res['message'] ?? 'Failed to reset password.';
                        });
                      }
                    }
                  },
                  child: isResetting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('RESET PASSWORD', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = _getSafeValue(_currentUser['name'], fallback: 'Member');
    final String initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    final String role = _getSafeValue(_currentUser['role'], fallback: 'CUSTOMER').toUpperCase();
    final String userId = _getSafeValue(_currentUser['user_id'], fallback: 'N/A');
    final String email = _getSafeValue(_currentUser['email'], fallback: 'N/A');

    final String rawPhone = _formatPhone10Digits(_currentUser['phone_number'] ?? _currentUser['phone']);
    final String displayPhone = rawPhone.isNotEmpty ? '+91 $rawPhone' : 'Not Set';
    final String gender = _getSafeValue(_currentUser['gender'], fallback: 'Male');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        elevation: 0,
        toolbarHeight: 65,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1C30), size: 18),
          onPressed: () => Navigator.pop(context, _currentUser),
        ),
        title: const Text(
          'MEMBER PROFILE',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: 1.2,
            color: Color(0xFF0B1C30),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0037B0)),
            tooltip: 'Edit Profile',
            onPressed: _openEditProfileDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0037B0)))
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Top Identity Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0037B0).withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: const Color(0xFF0037B0),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: Color(0xFF0B1C30),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: Color(0xFF0037B0),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Membership Details Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0037B0).withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MEMBERSHIP DETAILS',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Color(0xFF0037B0),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                          InkWell(
                            onTap: _openEditProfileDialog,
                            child: const Text(
                              'EDIT',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Color(0xFF0037B0),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.fingerprint_rounded, 'USER ID', userId),
                      const Divider(color: Color(0xFFE2E8F0), height: 24),
                      _buildDetailRow(Icons.email_outlined, 'EMAIL', email),
                      const Divider(color: Color(0xFFE2E8F0), height: 24),
                      _buildDetailRow(Icons.phone_outlined, 'PHONE', displayPhone),
                      const Divider(color: Color(0xFFE2E8F0), height: 24),
                      _buildDetailRow(Icons.person_outline_rounded, 'GENDER', gender),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _openChangePasswordDialog,
                    icon: const Icon(Icons.key_rounded, size: 16, color: Colors.white),
                    label: const Text('CHANGE PASSWORD'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0037B0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      textStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Reset Password via Email OTP Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _openForgotPasswordDialog,
                    icon: const Icon(Icons.mark_email_read_outlined, size: 16, color: Color(0xFF0037B0)),
                    label: const Text('RESET PASSWORD VIA EMAIL OTP'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0037B0),
                      side: const BorderSide(color: Color(0xFF0037B0), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      textStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const IndexScreen()),
                            (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                    label: const Text('SIGN OUT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      textStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0037B0)),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Color(0xFF747686),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF0B1C30),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}