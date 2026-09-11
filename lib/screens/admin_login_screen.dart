import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال كلمة المرور');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.adminLogin(password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      setState(() => _errorMessage = result['message'] ?? 'كلمة المرور غير صحيحة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تسجيل دخول المدير',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة القفل الفخمة
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 52,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'لوحة تحكم أسامة فون',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'هذه الواجهة مخصصة للمدير فقط لإضافة وإدارة المنتجات والخدمات على السيرفر المحلي.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // حقل كلمة المرور
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'كلمة مرور المدير',
                        labelStyle: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0B0F19),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0EA5E9)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white60,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.cairo(color: const Color(0xFFEF4444), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // زر تسجيل الدخول
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'تسجيل الدخول كمدير',
                                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'كلمة المرور الافتراضية: osama2026',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.white30),
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
