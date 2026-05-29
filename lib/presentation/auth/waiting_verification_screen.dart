import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';

class WaitingVerificationScreen extends ConsumerStatefulWidget {
  const WaitingVerificationScreen({super.key});

  @override
  ConsumerState<WaitingVerificationScreen> createState() => _WaitingVerificationScreenState();
}

class _WaitingVerificationScreenState extends ConsumerState<WaitingVerificationScreen> {
  Timer? _timer;
  int _secondsLeft = 180;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.reload();

    setState(() {
      _secondsLeft -= 3;
    });

    if (_auth.currentUser!.emailVerified) {
      _timer?.cancel();

      await _supabase
          .from('users')
          .update({'email_verified': true})
          .eq('firebase_uid', user.uid);

      await user.getIdToken(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email berhasil diverifikasi!'), backgroundColor: Color(0xFF1E8E3E), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    if (_secondsLeft <= 0) {
      _timer?.cancel();
      
      await ref.read(authRepositoryProvider).logout();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu verifikasi habis. Silakan login kembali dan pastikan link di email Anda sudah diklik.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    // Menghitung progress persentase untuk indikator lingkaran
    final double progress = _secondsLeft / 180; 

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // --- HEADER BACKGROUND ---
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- KARTU WAITING VERIFICATION ---
                    Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Animasi Stacked Icon (Loading Melingkari Ikon Email)
                          SizedBox(
                            height: 120,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    color: const Color(0xFFFF9800), // Warna orange
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), shape: BoxShape.circle),
                                  child: const Icon(Icons.mark_email_unread_outlined, size: 40, color: Color(0xFFFF9800)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          const Text(
                            'Verifikasi Email',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF25313A)),
                          ),
                          const SizedBox(height: 12),
                          
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                              children: [
                                const TextSpan(text: 'Kami telah mengirimkan tautan verifikasi ke:\n'),
                                TextSpan(
                                  text: '${_auth.currentUser?.email}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF25313A)),
                                ),
                                const TextSpan(text: '\n\nSilakan buka kotak masuk email Anda dan klik tautan tersebut untuk mengaktifkan akun.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // INDIKATOR WAKTU
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer_outlined, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Sisa waktu: $minutes:$seconds',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // --- TOMBOL BATAL ---
                    OutlinedButton.icon(
                      onPressed: () async {
                        _timer?.cancel();
                        await ref.read(authRepositoryProvider).logout();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Batalkan & Kembali', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}