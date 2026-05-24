import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // 1. PASTIKAN IMPORT INI ADA
import '../../data/repositories/auth_repository.dart';

class PetugasDashboard extends ConsumerWidget {
  const PetugasDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Petugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          // Parameter 'context' dikirim agar bisa digunakan untuk navigasi di dalam method
          _buildMenuCard(
            context,
            Icons.inventory,
            'Data Barang',
            Colors.orange,
          ),
          _buildMenuCard(
            context,
            Icons.directions_car,
            'Data Mobil',
            Colors.blue,
          ),
          _buildMenuCard(context, Icons.store, 'Data Toko', Colors.green),
          _buildMenuCard(
            context,
            Icons.add_shopping_cart,
            'Catat Pembelian',
            Colors.purple,
          ),
          _buildMenuCard(context, Icons.history, 'Riwayat', Colors.teal),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          12,
        ), // Efek ripple air mengikuti lengkungan kartu
        onTap: () {
          // 2. KODE NAVIGASI HARUS BERADA DI SINI
          if (title == 'Data Barang') {
            context.push('/barang');
          }
          if (title == 'Data Mobil') {
            context.push('/mobil');
          }
          if (title == 'Data Toko') {
            context.push('/toko');
          }
          if (title == 'Catat Pembelian') {
            context.push('/pencatatan');
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
