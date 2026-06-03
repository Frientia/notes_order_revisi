import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/providers/transaksi_draft_provider.dart';
import '../../domain/providers/barang_provider.dart';

class PetugasDashboard extends ConsumerWidget {
  const PetugasDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau state keranjang belanja (draft)
    final draftState = ref.watch(transaksiDraftProvider);
    // Memantau state barang untuk mengecek stok menipis
    final barangState = ref.watch(barangControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Dashboard Logistik', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Tambahan ikon notifikasi kecil untuk estetika modern
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada notifikasi baru')));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      // --- HAMBURGER MENU (DRAWER KIRI) ---
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.teal),
              ),
              accountName: const Text('Petugas Logistik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: const Text('Status: Aktif'),
            ),
            
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(context, Icons.add_shopping_cart, 'Catat Pembelian', '/pencatatan', Colors.purple),
                  _buildDrawerItem(context, Icons.history, 'Riwayat Transaksi', '/riwayat', Colors.teal),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text('Master Data', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  _buildDrawerItem(context, Icons.inventory_2_outlined, 'Data Barang', '/barang', Colors.orange),
                  _buildDrawerItem(context, Icons.directions_car_outlined, 'Data Mobil', '/mobil', Colors.blue),
                  _buildDrawerItem(context, Icons.storefront_outlined, 'Data Toko', '/toko', Colors.green),
                ],
              ),
            ),
            
            // Tombol Logout di bagian paling bawah
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konfirmasi Logout'),
                    content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref.read(authRepositoryProvider).logout();
                        },
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      
      // --- BODY UTAMA (RINGKASAN & INSIGHT) ---
      body: RefreshIndicator(
        onRefresh: () async {
          // Fitur tarik ke bawah (pull-to-refresh)
          ref.invalidate(barangControllerProvider);
          ref.invalidate(transaksiDraftProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KARTU SAMBUTAN
            const Text('Selamat Datang,', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const Text('Petugas Lapangan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // KARTU 1: STATUS DRAFT KERANJANG BELANJA
            if (draftState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (draftState.idPencatatan != null && draftState.items.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.purple, Colors.deepPurple]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.purple.withAlpha(77), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.pending_actions, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Ada Transaksi Belum Selesai!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Draft #${draftState.idPencatatan} memiliki ${draftState.items.length} item di dalam Pencatatan yang belum di-selesaikan.', style: TextStyle(color: Colors.white.withAlpha(230))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.purple,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => context.push('/pencatatan'),
                        child: const Text('Lanjutkan Pencatatan', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),

            // KARTU 2: PERINGATAN STOK MENIPIS
            barangState.when(
              data: (listBarang) {
                // Saring barang yang stoknya di bawah 5
                final lowStockItems = listBarang.where((b) => b.stock < 5).toList();
                
                if (lowStockItems.isEmpty) return const SizedBox(); // Sembunyikan jika aman

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade100, width: 2),
                    boxShadow: [BoxShadow(color: Colors.red.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('Peringatan Stok Menipis', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Text('${lowStockItems.length} Item', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Tampilkan maksimal 3 barang sebagai cuplikan
                        ...lowStockItems.take(3).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('• ${item.namaBarang}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text('Sisa: ${item.stock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                        if (lowStockItems.length > 3)
                          Text('...dan ${lowStockItems.length - 3} barang lainnya.', style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.shade200),
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => context.push('/barang'),
                          child: const Text('Cek Master Barang'),
                        )
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const SizedBox(),
            ),

            // KARTU 3: JALAN PINTAS (SHORTCUTS)
            const Text('Aksi Cepat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(context, Icons.add_circle, 'Catat Baru', Colors.purple, () => context.push('/pencatatan')),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionCard(context, Icons.history, 'Cetak Laporan', Colors.teal, () => context.push('/riwayat')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET HELPER: Item List Menu di Drawer
  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String route, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.pop(context); // Tutup drawer dulu
        context.push(route);    // Baru pindah halaman
      },
    );
  }

  // WIDGET HELPER: Tombol Kotak Jalan Pintas di Layar Utama
  Widget _buildQuickActionCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withAlpha(26), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}