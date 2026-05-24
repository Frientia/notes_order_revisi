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
          const SnackBar(content: Text('Email berhasil diverifikasi!'), backgroundColor: Colors.green),
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
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_unread, size: 100, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Verifikasi Email Anda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Kami telah mengirimkan tautan verifikasi ke email:\n${_auth.currentUser?.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 32),
            const Center(
              child: SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Menunggu verifikasi... Sisa waktu: $minutes:$seconds',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () async {
                _timer?.cancel();
                await ref.read(authRepositoryProvider).logout();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Batalkan & Kembali ke Login'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}