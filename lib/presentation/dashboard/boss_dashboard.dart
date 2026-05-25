import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dashboard_boss_repository.dart';
import '../../domain/providers/dashboard_boss_provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/formatters.dart'; // Aktifkan formatter kembali

class BossDashboard extends ConsumerWidget {
  const BossDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau state data dashboard (Loading / Error / Success)
    final dashboardState = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Dashboard Eksekutif',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async =>
                await ref.read(authRepositoryProvider).logout(),
          ),
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

                  // 1. MENU RIWAYAT KESELURUHAN
                  ListTile(
                    leading: const Icon(Icons.list_alt, color: Colors.indigo),
                    title: const Text('Riwayat Keseluruhan'),
                    onTap: () {
                      Navigator.pop(context); // 1. Tutup drawer terlebih dahulu
                      context.push(
                        '/riwayat',
                      ); // 2. Pindah ke rute halaman riwayat
                    },
                  ),

                  // 2. MENU AKUNTABILITAS PETUGAS (Pengganti rekap kendaraan)
                  ListTile(
                    leading: const Icon(
                      Icons.assignment_ind,
                      color: Colors.orange,
                    ), // Ganti ikon agar sesuai petugas
                    title: const Text('Akuntabilitas Petugas'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        '/log-petugas',
                      ); // Pindah ke rute halaman log petugas
                    },
                  ),

                  // 3. MENU REKAP HUTANG TOKO
                  ListTile(
                    leading: const Icon(Icons.store, color: Colors.teal),
                    title: const Text('Rekap Hutang Toko'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        '/rekap-hutang',
                      ); // Pindah ke rute halaman hutang (jika sudah ada)
                    },
                  ),

                  const Divider(),

                  // 4. MENU CETAK LAPORAN PDF
                  ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.redAccent,
                    ),
                    title: const Text('Cetak Laporan PDF'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/cetak-pdf');
                    },
                  ),
                ],
              ),
            ),
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
            // Fitur tarik ke bawah untuk me-refresh data
            onRefresh: () async => ref.refresh(dashboardDataProvider),
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

                  // SECTION: KPI CARDS MEMAKAI DATA ASLI
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
                  const SizedBox(height: 32),

                  // SECTION: GRAFIK MEMAKAI DATA ASLI
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
                          color: Colors.grey.withOpacity(0.1),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isFullWidth ? 22 : 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
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

  // --- KONFIGURASI GRAFIK DINAMIS ---
  LineChartData _buildCombinedChartData(DashboardData data) {
    // Mengubah Rupiah menjadi satuan "Juta" agar muat di sumbu Y grafik
    List<double> belanjaJutaan = data.belanja6Bulan
        .map((e) => e / 1000000)
        .toList();

    // Mencari batas atas grafik (Max Y) secara dinamis agar grafik tidak terpotong
    double maxBelanja = belanjaJutaan.isNotEmpty
        ? belanjaJutaan.reduce(max)
        : 0;
    double maxTransaksi = data.transaksi6Bulan.isNotEmpty
        ? data.transaksi6Bulan.reduce(max).toDouble()
        : 0;
    double highestY = max(maxBelanja, maxTransaksi);
    double maxYLimit = highestY > 0
        ? highestY + (highestY * 0.2)
        : 10; // Tambah 20% ruang kosong di atas

    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 35),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 5,
      minY: 0,
      maxY: maxYLimit, // Skala Y Dinamis

      lineBarsData: [
        // 1. Garis Belanja (Satuan Juta)
        LineChartBarData(
          spots: List.generate(
            6,
            (i) => FlSpot(i.toDouble(), belanjaJutaan[i]),
          ),
          isCurved: true,
          color: Colors.blue,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
        // 2. Garis Transaksi
        LineChartBarData(
          spots: List.generate(
            6,
            (i) => FlSpot(i.toDouble(), data.transaksi6Bulan[i].toDouble()),
          ),
          isCurved: true,
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
