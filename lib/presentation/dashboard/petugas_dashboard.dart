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
    final draftState = ref.watch(transaksiDraftProvider);
    final barangState = ref.watch(barangControllerProvider);
    final primaryColor = const Color(0xFF1E3A5F);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Dashboard Logistik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24, 
                left: 24, 
                right: 24, 
                bottom: 24
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A5F),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white, // Kontras dengan background Navy
                    child: const Icon(Icons.person, size: 36, color: Color(0xFF1E3A5F)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Petugas Logistik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: const Text('Status: Aktif', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text('MENU UTAMA', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                  ),
                  _buildDrawerItem(context, Icons.add_shopping_cart, 'Catat Pembelian', '/pencatatan', const Color(0xFF1E3A5F)),
                  _buildDrawerItem(context, Icons.history, 'Riwayat Pencatatan Transaksi', '/riwayat', Colors.black87),
                  
                  const Padding(
                    padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
                    child: Text('MASTER DATA', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                  ),
                  _buildDrawerItem(context, Icons.inventory_2_outlined, 'Data Barang', '/barang', Colors.orange.shade700),
                  _buildDrawerItem(context, Icons.storefront_outlined, 'Data Toko', '/toko', Colors.green.shade600),
                  _buildDrawerItem(context, Icons.directions_car_outlined, 'Data Mobil', '/mobil', Colors.blue.shade600),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),
            Padding(
              padding: EdgeInsets.only(
                left: 16, 
                right: 16, 
                top: 16, 
                bottom: MediaQuery.of(context).padding.bottom + 16
              ),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Konfirmasi Logout'),
                      content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
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
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(barangControllerProvider);
          ref.invalidate(transaksiDraftProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40, top: 10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selamat Datang,', style: TextStyle(fontSize: 16, color: const Color(0xFF1E3A5F).withAlpha(40))),
                    const SizedBox(height: 4),
                    const Text('Petugas Lapangan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total Barang',
                              value: barangState.maybeWhen(data: (list) => list.length.toString(), orElse: () => '...'),
                              icon: Icons.inventory_2,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Draft Aktif',
                              value: draftState.items.length.toString(),
                              icon: Icons.pending_actions,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Aksi Cepat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(context, Icons.add_shopping_cart, 'Catat Baru', primaryColor, () => context.push('/pencatatan')),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildQuickActionButton(context, Icons.history, 'Riwayat Pencatatan Transaksi', Colors.black87, () => context.push('/riwayat')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text('Status Pekerjaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                      const SizedBox(height: 12),
                      if (draftState.isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                      else if (draftState.idPencatatan != null && draftState.items.isNotEmpty)
                        _buildDraftCard(context, draftState)
                      else
                        _buildEmptyState(
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          title: 'Pekerjaan Tuntas!',
                          subtitle: 'Tidak ada draft Pencatatan Transaksi yang tertunda saat ini.',
                        ),
                      const SizedBox(height: 24),
                      const Text('Peringatan Inventaris', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                      const SizedBox(height: 12),
                      barangState.when(
                        data: (listBarang) {
                          final lowStockItems = listBarang.where((b) => b.stock < 5).toList();
                          if (lowStockItems.isEmpty) {
                            return _buildEmptyState(
                              icon: Icons.inventory_2_outlined,
                              color: Colors.blue,
                              title: 'Stok Aman',
                              subtitle: 'Semua barang memiliki jumlah stok yang cukup.',
                            );
                          }
                          return _buildLowStockCard(context, lowStockItems);
                        },
                        loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                        error: (e, s) => const SizedBox(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String route, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          context.push(route);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 14)),
              ),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color.withAlpha(150)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDraftCard(BuildContext context, dynamic draftState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrange.shade500]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.orange.withAlpha(70), blurRadius: 15, offset: const Offset(0, 8))],
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
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Draft Belum Diselesaikan!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
            const SizedBox(height: 16),
            Text('Draft #${draftState.idPencatatan} memiliki ${draftState.items.length} item yang masih menggantung.', style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepOrange,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => context.push('/pencatatan'),
              child: const Text('Lanjutkan Pencatatan', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockCard(BuildContext context, List<dynamic> lowStockItems) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.red.withAlpha(20), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Stok Menipis', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text('${lowStockItems.length} Item', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const Divider(height: 24),
            ...lowStockItems.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(item.namaBarang, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(6)),
                    child: Text('Sisa: ${item.stock}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            )),
            if (lowStockItems.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('...dan ${lowStockItems.length - 3} barang lainnya.', style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.push('/barang'),
              child: const Text('Cek Master Barang', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}