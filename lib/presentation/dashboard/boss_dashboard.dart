import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dashboard_boss_repository.dart';
import '../../domain/providers/dashboard_boss_provider.dart';
import '../../domain/providers/riwayat_provider_boss.dart'; // Import untuk recentTransaksiDashboardProvider
import '../../core/utils/formatters.dart';

// --- IMPORT UNTUK FITUR TITIK MERAH NOTIFIKASI ---
import '../../domain/providers/riwayat_notif_boss_provider.dart';
import '../../domain/providers/read_notif_provider.dart';

class BossDashboard extends ConsumerWidget {
  const BossDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau state data dashboard utama (Loading / Error / Success)
    final dashboardState = ref.watch(dashboardDataProvider);

    // --- LOGIKA MENGHITUNG NOTIFIKASI BELUM DIBACA ---
    final listNotifAsync = ref.watch(riwayatNotifBossProvider);
    final readNotifs = ref.watch(readNotificationsProvider);
    
    int unreadCount = 0;
    listNotifAsync.whenData((listData) {
      // Hitung data yang ID-nya BELUM ADA di dalam memori yang sudah dibaca
      unreadCount = listData.where((data) {
        return !readNotifs.contains(data['id_pencatatan']);
      }).length;
    });

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Dashboard Executive',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // --- IKON LONCENG DENGAN TITIK MERAH (TANPA ANGKA) ---
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_active),
                tooltip: 'Kotak Masuk Notifikasi',
                onPressed: () {
                  context.push('/notifikasi'); 
                },
              ),
              // Jika ada notifikasi baru, munculkan titik merah kecil elegan
              if (unreadCount > 0)
                Positioned(
                  right: 11, // Posisi digeser agar pas di lekukan lonceng
                  top: 11,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blueGrey[800]!, // Warna border senada dengan AppBar
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8), // Sedikit jarak di kanan AppBar
        ],
      ),

      // --- HAMBURGER MENU (SIDEBAR) ---
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey[800]),
              accountName: const Text(
                'Pimpinan PT Lahir Barutama',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text('Akses: Eksekutif (Read-Only)'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blueGrey),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      'LAPORAN ANALISIS',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.list_alt, color: Colors.indigo),
                    title: const Text('Riwayat Keseluruhan'),
                    onTap: () {
                      Navigator.pop(context); 
                      context.push('/riwayat-boss'); 
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.assignment_ind, color: Colors.orange),
                    title: const Text('Akuntabilitas Petugas'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/log-petugas');
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.store, color: Colors.teal),
                    title: const Text('Rekap Hutang Toko'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/rekap-hutang');
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    title: const Text('Cetak Laporan PDF'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/cetak-laporan');
                    },
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Keluar',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                Navigator.pop(context); 
                await ref.read(authRepositoryProvider).logout();
              },
            ),
            const SizedBox(height: 16), 
          ],
        ),
      ),

      // --- BODY UTAMA DENGAN RIVERPOD STATE ---
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Terjadi Kesalahan:\n$err', textAlign: TextAlign.center),
        ),

        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardDataProvider);
              ref.invalidate(recentTransaksiDashboardProvider);
              try {
                await ref.read(dashboardDataProvider.future);
              } catch (_) {}
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Operasional',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // SECTION: KPI CARDS
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Belanja (Bulan Ini)',
                          value: AppFormatters.rupiah(
                            data.totalBelanjaBulanIni,
                          ),
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Total Hutang',
                          value: AppFormatters.rupiah(data.totalHutang),
                          icon: Icons.money_off,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildKpiCard(
                    title: 'Total Transaksi (Bulan Ini)',
                    value: '${data.totalTransaksiBulanIni} Nota',
                    icon: Icons.receipt_long,
                    color: Colors.green,
                    isFullWidth: true,
                  ),

                  const SizedBox(height: 24),

                  // --- WIDGET TABEL 5 TRANSAKSI TERBARU HARI INI ---
                  _buildRecentTransactionsTable(context, ref),

                  const SizedBox(height: 24),

                  // SECTION: GRAFIK
                  const Text(
                    'Grafik Pengadaan Sparepart (6 Bulan)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildLegendItem(Colors.blue, 'Uang Belanja (Jutaan)'),
                      const SizedBox(width: 16),
                      _buildLegendItem(Colors.green, 'Jml Transaksi'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    height: 300,
                    padding: const EdgeInsets.only(
                      right: 16,
                      left: 8,
                      top: 24,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LineChart(_buildCombinedChartData(data)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10), 
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ), 
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11, 
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isFullWidth ? 22 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsTable(BuildContext context, WidgetRef ref) {
    final recentData = ref.watch(recentTransaksiDashboardProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '5 Pencatatan Terbaru Hari Ini',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            recentData.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Gagal memuat data tabel: $err',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
              data: (listData) {
                if (listData.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Belum ada transaksi masuk hari ini.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.resolveWith(
                          (states) => Colors.grey[50],
                        ),
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 50,
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'No',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Petugas',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Kategori',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Nama Barang',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'No Plat',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Qty',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Harga Satuan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: List.generate(listData.length, (index) {
                          final item = listData[index];
                          return DataRow(
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(
                                Text(
                                  item.namaPetugas,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.kategoriBarang,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(item.namaBarang)),
                              DataCell(
                                Text(
                                  item.nopolMobil,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              DataCell(Text('${item.qty}')),
                              DataCell(Text(AppFormatters.rupiah(item.harga))),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          side: const BorderSide(color: Colors.indigo),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          context.push('/riwayat-boss');
                        },
                        child: const Text(
                          'Lihat pencatatan selanjutnya ->',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- KONFIGURASI GRAFIK DINAMIS (REFACTORING UI) ---
  LineChartData _buildCombinedChartData(DashboardData data) {
    // Data diubah ke jutaan untuk skala grafik
    List<double> belanjaJutaan = data.belanja6Bulan
        .map((e) => e / 1000000)
        .toList();

    double maxBelanja = belanjaJutaan.isNotEmpty ? belanjaJutaan.reduce(max) : 0;
    double maxTransaksi = data.transaksi6Bulan.isNotEmpty ? data.transaksi6Bulan.reduce(max).toDouble() : 0;
    
    // Mencari titik tertinggi untuk batas atas grafik
    double highestY = max(maxBelanja, maxTransaksi);
    double maxYLimit = highestY > 0 ? highestY + (highestY * 0.2) : 10;
    
    // Menentukan jarak antar angka di sumbu Y agar tidak tumpang tindih
    double intervalY = (maxYLimit / 5).ceilToDouble();
    if (intervalY == 0) intervalY = 1; // Mencegah interval 0 jika data kosong

    return LineChartData(
      gridData: FlGridData(
        show: true, 
        drawVerticalLine: false,
        horizontalInterval: intervalY, // Garis grid mengikuti interval Y
      ),
      
      // --- PERBAIKAN TOOLTIP SAAT GRAFIK DITEKAN ---
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          // Warna background pop-up tooltip
          getTooltipColor: (touchedSpot) => Colors.blueGrey.shade900,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              // Index 0 = Uang Belanja (Biru), Index 1 = Jml Transaksi (Hijau)
              final isBelanja = spot.barIndex == 0;
              
              if (isBelanja) {
                // Kembalikan ke nilai asli (dikali 1 juta) untuk ditampilkan sbg Rupiah
                final double realValue = spot.y * 1000000;
                return LineTooltipItem(
                  AppFormatters.rupiah(realValue),
                  const TextStyle(
                    color: Colors.lightBlueAccent, 
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              } else {
                // Tampilan untuk Jml Transaksi
                return LineTooltipItem(
                  '${spot.y.toInt()} Nota',
                  const TextStyle(
                    color: Colors.greenAccent, 
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              }
            }).toList();
          },
        ),
      ),

      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < 6) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data.labelBulan[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600]
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        
        // --- PERBAIKAN SUMBU Y AGAR RAPI & TIDAK TUMPANG TINDIH ---
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 35, // Ruang lega untuk angka
            interval: intervalY, // Memaksa jarak angka konstan (misal: 0, 5, 10, 15)
            getTitlesWidget: (value, meta) {
              // Menghilangkan angka desimal, tampilkan angka bulat saja
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 5,
      minY: 0,
      maxY: maxYLimit,

      lineBarsData: [
        // 1. GARIS BIRU (UANG BELANJA)
        LineChartBarData(
          spots: List.generate(
            6,
            (i) => FlSpot(i.toDouble(), belanjaJutaan[i]),
          ),
          isCurved: true,
          preventCurveOverShooting: true, // PERBAIKAN: Cegah lengkungan menukik di bawah 0
          color: Colors.blue,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1), // Gunakan withOpacity untuk Flutter versi aman
          ),
        ),
        
        // 2. GARIS HIJAU (JML TRANSAKSI)
        LineChartBarData(
          spots: List.generate(
            6,
            (i) => FlSpot(i.toDouble(), data.transaksi6Bulan[i].toDouble()),
          ),
          isCurved: true,
          preventCurveOverShooting: true, // PERBAIKAN: Cegah lengkungan menukik di bawah 0
          color: Colors.green,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }
}