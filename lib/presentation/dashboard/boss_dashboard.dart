import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import '../../data/repositories/auth_repository.dart';

class BossDashboard extends ConsumerWidget {
  const BossDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        // Hamburger menu icon otomatis muncul di kiri karena kita pakai Drawer
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
            },
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
                  ListTile(
                    leading: const Icon(Icons.list_alt, color: Colors.indigo),
                    title: const Text('Riwayat Keseluruhan'),
                    onTap: () {
                      Navigator.pop(context); // Tutup drawer
                      // TODO: Navigasi
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.local_shipping,
                      color: Colors.orange,
                    ),
                    title: const Text('Rekap per Kendaraan'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigasi
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.store, color: Colors.teal),
                    title: const Text('Rekap Hutang Toko'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigasi
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.redAccent,
                    ),
                    title: const Text('Cetak Laporan PDF'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigasi
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // --- BODY UTAMA (KPI & GRAFIK) ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sapaan
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
                    value: 'Rp 15.4M', // Dummy
                    icon: Icons.account_balance_wallet,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Hutang',
                    value: 'Rp 4.2M', // Dummy
                    icon: Icons.money_off,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildKpiCard(
              title: 'Total Transaksi (Nota)',
              value: '128 Nota', // Dummy
              icon: Icons.receipt_long,
              color: Colors.green,
              isFullWidth: true,
            ),
            const SizedBox(height: 32),

            // SECTION: GRAFIK ANALISIS
            const Text(
              'Grafik Pengadaan Sparepart (6 Bulan Terakhir)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(Colors.blue, 'Uang Belanja (Juta)'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.green, 'Jml Transaksi'),
              ],
            ),
            const SizedBox(height: 16),

            // Container Grafik
            Container(
              height: 300, // Tinggi grafik
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
              child: LineChart(
                _buildCombinedChartData(), // Memanggil fungsi grafik
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: KPI CARD ---
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
                    fontSize: isFullWidth ? 22 : 16,
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

  // --- WIDGET HELPER: LEGEND GRAFIK ---
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

  // --- KONFIGURASI GRAFIK FL_CHART ---
  LineChartData _buildCombinedChartData() {
    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        // Label Bulan di sumbu X
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun'];
              if (value.toInt() >= 0 && value.toInt() < months.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    months[value.toInt()],
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
        // Label Angka di sumbu Y (Sebelah kiri)
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 20,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 5,
      minY: 0,
      maxY: 100, // Skala maksimal (Disesuaikan nanti dengan data asli)
      // GARIS GRAFIK
      lineBarsData: [
        // 1. Garis Total Belanja (Warna Biru) - Misal skalanya dlm puluhan juta
        LineChartBarData(
          spots: const [
            FlSpot(0, 45),
            FlSpot(1, 60),
            FlSpot(2, 55),
            FlSpot(3, 80),
            FlSpot(4, 65),
            FlSpot(5, 90),
          ],
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
        // 2. Garis Total Transaksi (Warna Hijau) - Misal jumlah nota per bulan
        LineChartBarData(
          spots: const [
            FlSpot(0, 20),
            FlSpot(1, 25),
            FlSpot(2, 22),
            FlSpot(3, 40),
            FlSpot(4, 30),
            FlSpot(5, 50),
          ],
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
