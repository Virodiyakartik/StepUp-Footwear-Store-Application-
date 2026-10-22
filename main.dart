import 'dart:math';
import 'package:flutter/material.dart';
import 'signup.dart';
import 'splash.dart';
import 'index.dart';
import 'api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StepUp | Forever Faster',
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8F9FF),
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0037B0),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF0B1C30),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0B1C30)),
          bodyMedium: TextStyle(color: Color(0xFF0B1C30)),
          bodySmall: TextStyle(color: Color(0xFF434655)),
          titleLarge: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.w800),
          titleMedium: TextStyle(color: Color(0xFF0B1C30), fontWeight: FontWeight.w700),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 3D Auto-Redirecting Popup
  void _show3dSuccessDialog({required String title, required String message, required VoidCallback onAutoRedirect}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'SuccessDialog',
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
                      color: const Color(0xFF0037B0).withValues(alpha: 0.15),
                      blurRadius: 36,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
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
                          colors: [Color(0xFF2563EB), Color(0xFF0037B0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0037B0).withValues(alpha: 0.35),
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
                        child: const Icon(Icons.check_rounded, color: Color(0xFF0037B0), size: 44),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Color(0xFF0B1C30),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
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
                        color: Color(0xFF0037B0),
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

  // FORGOT PASSWORD VIA EMAIL OTP DIALOG
  void _openForgotPasswordDialog() {
    int step = 1;
    String generatedOtp = '';
    bool isSendingOtp = false;
    bool isResetting = false;
    String? dialogError;

    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    final otpController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final stepFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> sendOtp() async {
            final targetEmail = resetEmailController.text.trim();
            if (targetEmail.isEmpty || !targetEmail.contains('@')) {
              setDialogState(() => dialogError = 'Enter a valid email address!');
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
              target: targetEmail,
              otp: generatedOtp,
              name: 'Member',
            );

            setDialogState(() => isSendingOtp = false);

            if (res['status'] == 'SUCCESS') {
              setDialogState(() {
                step = 2;
                dialogError = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification code sent to $targetEmail. Check Inbox/Spam!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            } else {
              setDialogState(() {
                dialogError = res['message'] ?? 'Failed to send verification code.';
              });
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            title: Row(
              children: [
                const Icon(Icons.lock_reset, color: Color(0xFF0037B0), size: 24),
                const SizedBox(width: 8),
                Text(
                  step == 1 ? 'RESET PASSWORD' : (step == 2 ? 'ENTER OTP' : 'SET NEW PASSWORD'),
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
                            borderRadius: BorderRadius.circular(8),
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
                          'Enter your registered email to receive a 6-digit verification code:',
                          style: TextStyle(color: Color(0xFF434655), fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: resetEmailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Color(0xFF0B1C30), fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'REGISTERED EMAIL',
                            labelStyle: const TextStyle(color: Color(0xFF747686), fontSize: 11, fontWeight: FontWeight.w700),
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0037B0), size: 18),
                            filled: true,
                            fillColor: const Color(0xFFEFF4FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                        ),
                      ],
                      if (step == 2) ...[
                        Text(
                          'Enter the 6-digit code sent to:\n${resetEmailController.text.trim()}',
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (v) => (v == null || v.trim().length != 6) ? 'Enter 6-digit OTP' : null,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: isSendingOtp ? null : () => sendOtp(),
                            icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF0037B0)),
                            label: const Text('Resend Code', style: TextStyle(color: Color(0xFF0037B0), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                      if (step == 3) ...[
                        const Text(
                          'OTP verified! Create your new password.',
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                  onPressed: isSendingOtp ? null : () => sendOtp(),
                  child: isSendingOtp
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SEND OTP', style: TextStyle(fontWeight: FontWeight.w900)),
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
                        setDialogState(() => dialogError = 'Invalid OTP code! Please check your email.');
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

                      final updateRes = await ApiService.changePassword(
                        userId: '',
                        oldPassword: '',
                        newPassword: newPassController.text.trim(),
                      );

                      if (!mounted) return;

                      if (updateRes['status'] == 'SUCCESS') {
                        Navigator.pop(ctx);
                        _passwordController.text = newPassController.text.trim();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated successfully! Please sign in.'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          isResetting = false;
                          dialogError = updateRes['message'] ?? 'Failed to update password. Try again.';
                        });
                      }
                    }
                  },
                  child: isResetting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SAVE PASSWORD', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleLogin() async {
    final inputEmail = _emailController.text.trim();
    final inputPassword = _passwordController.text.trim();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await ApiService.loginUser(
        email: inputEmail,
        password: inputPassword,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['status'] == 'SUCCESS') {
        final userData = result['user'] as Map<String, dynamic>?;
        final userName = userData != null ? (userData['name'] ?? 'Member') : 'Member';

        _show3dSuccessDialog(
          title: 'LOGIN SUCCESSFUL',
          message: 'Welcome back, $userName!\nRedirecting to store...',
          onAutoRedirect: () {
            Navigator.pop(context);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => IndexScreen(currentUser: userData),
              ),
                  (route) => false,
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Invalid email or password!'),
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF0037B0)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/Logo.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'STEPUP',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Color(0xFF0B1C30),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                      'MEMBER ACCESS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Login to unlock exclusive drops & rapid checkout.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF434655),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Enter email';
                        if (!value.contains('@')) return 'Enter valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Enter password';
                        if (value.length < 6) return 'Minimum 6 chars';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password Text Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: _openForgotPasswordDialog,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF0037B0),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
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
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text(
                        'SIGN IN',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "New to StepUp?",
                          style: TextStyle(fontFamily: 'Inter', color: Color(0xFF434655), fontSize: 12.5),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupPage()),
                            );
                          },
                          child: const Text(
                            'JOIN NOW',
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