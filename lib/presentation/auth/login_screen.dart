import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      await ref.read(authControllerProvider.notifier).login(
            _emailCtrl.text.trim(),
            _passwordCtrl.text.trim(),
          );
      
      final authState = ref.read(authControllerProvider);
      if (mounted) {
        if (authState.hasError) {
          _showSnackBar(
            _translateError(authState.error.toString()),
            Colors.red.shade600,
          );
        } else {
          _showSnackBar('Berhasil masuk!', Colors.green.shade600);
        }
      }
    }
  }

  String _translateError(String error) {
    final msg = error.toLowerCase();
    if (msg.contains('invalid') || msg.contains('wrong password')) {
      return 'Email atau Kata Sandi salah!';
    } else if (msg.contains('user not found')) {
      return 'Akun tidak ditemukan.';
    } else if (msg.contains('network')) {
      return 'Koneksi internet bermasalah.';
    }
    return error.replaceAll('Exception: ', '');
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF25313A), Color(0xFF3B56B9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white.withAlpha(26), shape: BoxShape.circle),
                            child: const Icon(Icons.corporate_fare, size: 64, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          const Text('PT Lahir Barutama', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Text('Sistem Pencatatan Pembelian', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 14)),
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(32.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Masuk ke Akun', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF25313A)), textAlign: TextAlign.center),
                                  const SizedBox(height: 24),
                                  _buildTextField(
                                    controller: _emailCtrl,
                                    label: 'Alamat Email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) => (v == null || !RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(v.trim())) ? 'Email tidak valid' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _passwordCtrl,
                                    label: 'Kata Sandi',
                                    icon: Icons.lock_outline,
                                    obscure: _obscureText,
                                    suffix: IconButton(
                                      icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                                      onPressed: () => setState(() => _obscureText = !_obscureText),
                                    ),
                                    validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton(
                                    onPressed: isLoading ? null : _submitLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B56B9),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                        : const Text('MASUK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(color: Colors.grey),
                                children: [TextSpan(text: 'Daftar di sini', style: TextStyle(color: Color(0xFF3B56B9), fontWeight: FontWeight.bold))],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B56B9), width: 1.5)),
      ),
      validator: validator,
    );
  }
}