import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dashboard_boss_repository.dart';
import '../../domain/providers/dashboard_boss_provider.dart';
import '../../domain/providers/riwayat_provider_boss.dart';
import '../../core/utils/formatters.dart';

import '../../domain/providers/riwayat_notif_boss_provider.dart';
import '../../domain/providers/read_notif_provider.dart';

// ─────────────────────────────────────────────
// DESIGN TOKENS — LIGHT
// ─────────────────────────────────────────────
class _P {
  static const bg = Color(0xFFF8F9FB); // page background
  static const surface = Color(0xFFFFFFFF); // card surface
  static const surfaceAlt = Color(0xFFF1F5F9); // alt row
  static const border = Color(0xFFE2E8F0); // divider

  // text
  static const t1 = Color(0xFF0F172A); // primary
  static const t2 = Color(0xFF475569); // secondary
  static const t3 = Color(0xFF94A3B8); // muted/hint

  // accents
  static const blue = Color(0xFF2563EB);
  static const blueL = Color(0xFFEFF6FF);
  static const red = Color(0xFFDC2626);
  static const redL = Color(0xFFFEF2F2);
  static const green = Color(0xFF16A34A);
  static const greenL = Color(0xFFF0FDF4);
  static const amber = Color(0xFFD97706);
  static const indigo = Color(0xFF4F46E5);
  static const teal = Color(0xFF0D9488);
  static const tealL = Color(0xFFF0FDFA);

  // AppBar
  static const bar = Color(0xFF1E3A5F);
  static const barFg = Color(0xFFFFFFFF);
}

// ─────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────
class BossDashboard extends ConsumerWidget {
  const BossDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardDataProvider);

    final listNotifAsync = ref.watch(riwayatNotifBossProvider);

    int unreadCount = 0;
    listNotifAsync.whenData((listData) {
      unreadCount = listData
          .where((d) => d['is_read'] != true)
          .length;
    });

    return Scaffold(
      backgroundColor: _P.bg,
      appBar: _buildAppBar(context, unreadCount),
      drawer: _ModernDrawer(ref: ref, ctx: context),
      body: dashboardState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _P.blue)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: _P.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat data',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _P.red,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                err.toString(),
                style: const TextStyle(color: _P.t2, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (data) => RefreshIndicator(
          color: _P.blue,
          onRefresh: () async {
            ref.invalidate(dashboardDataProvider);
            ref.invalidate(recentTransaksiDashboardProvider);
            try {
              await ref.read(dashboardDataProvider.future);
            } catch (_) {}
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(
                  'Ringkasan Operasional',
                  icon: Icons.dashboard_rounded,
                  color: _P.blue,
                ),
                const SizedBox(height: 12),

                // ─── PERBAIKAN DOSEN: ROW KPI SEKARANG BISA DI-DIRECT KLIK ───
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        title: 'Total Belanja',
                        value: AppFormatters.rupiah(data.totalBelanjaSemua),
                        subtitle: 'Bulan ini: ${AppFormatters.rupiah(data.totalBelanjaBulanIni)}',
                        icon: Icons.account_balance_wallet_rounded,
                        accent: _P.blue,
                        accentLight: _P.blueL,
                        onTap: () => context.push('/riwayat-boss'), // Direct ke halaman Riwayat Keseluruhan
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _KpiCard(
                        title: 'Total Hutang',
                        value: AppFormatters.rupiah(data.totalHutangSemua),
                        subtitle: 'Bulan ini: ${AppFormatters.rupiah(data.totalHutangBulanIni)}',
                        icon: Icons.money_off_rounded,
                        accent: _P.red,
                        accentLight: _P.redL,
                        onTap: () => context.push('/rekap-hutang'), // Direct ke halaman Rekap Hutang Toko
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _KpiCard(
                  title: 'Total Transaksi',
                  value: '${data.totalTransaksiSemua} Nota',
                  subtitle: 'Bulan ini: ${data.totalTransaksiBulanIni} Nota',
                  icon: Icons.receipt_long_rounded,
                  accent: _P.green,
                  accentLight: _P.greenL,
                  isWide: true,
                  onTap: () => context.push('/riwayat-boss'), // Direct shortcut ke list dokumen nota
                ),

                const SizedBox(height: 28),

                _SectionLabel(
                  '5 Pencatatan Terbaru Hari Ini',
                  icon: Icons.bolt_rounded,
                  color: _P.amber,
                ),
                const SizedBox(height: 12),
                _RecentTransactionsCard(ref: ref, ctx: context),

                const SizedBox(height: 28),

                _SectionLabel(
                  'Grafik Pengadaan Sparepart (6 Bulan)',
                  icon: Icons.show_chart_rounded,
                  color: _P.indigo,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _LegendDot(color: _P.blue, label: 'Uang Belanja (Jutaan)'),
                    const SizedBox(width: 20),
                    _LegendDot(color: _P.teal, label: 'Jml Transaksi'),
                  ],
                ),
                const SizedBox(height: 14),
                _ChartCard(data: data),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, int unreadCount) {
    return AppBar(
      backgroundColor: _P.bar,
      foregroundColor: _P.barFg,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'EXEC',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2.5,
              ),
            ),
          ),
          const Text(
            'Dashboard Executive',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded, size: 22),
              tooltip: 'Notifikasi',
              onPressed: () {
                context.push('/notifikasi');
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 11,
                top: 11,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                    border: Border.all(color: _P.bar, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _SectionLabel(this.text, {required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _P.t1,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────
// KPI CARD (FIXED INTERACTIVE CLICK WITH INKWELL)
// ─────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final Color accentLight;
  final bool isWide;
  final VoidCallback onTap; // Parameter callback tap baru

  const _KpiCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.accent,
    required this.accentLight,
    this.isWide = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accentLight,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: accent, size: 20),
    );

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: _P.t2,
            fontWeight: FontWeight.w500,
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
              fontSize: isWide ? 24 : 18,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: _P.t3),
          ),
        ],
      ],
    );

    // Menggunakan Material + InkWell agar efek ripple klik terlihat profesional di atas warna putih
    return Material(
      color: _P.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _P.border),
          ),
          child: isWide
              ? Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 14),
                    Expanded(child: textBlock),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [iconWidget, const SizedBox(height: 12), textBlock],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RECENT TRANSACTIONS CARD
// ─────────────────────────────────────────────
class _RecentTransactionsCard extends StatelessWidget {
  final WidgetRef ref;
  final BuildContext ctx;
  const _RecentTransactionsCard({required this.ref, required this.ctx});

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SELESAI':
      case 'LUNAS':
        return _P.green;
      case 'PENDING':
        return _P.amber;
      default:
        return _P.t2;
    }
  }

  Color _statusBackground(String status) {
    switch (status.toUpperCase()) {
      case 'SELESAI':
      case 'LUNAS':
        return _P.greenL;
      case 'PENDING':
        return const Color(0xFFFFFBEB);
      default:
        return _P.surfaceAlt;
    }
  }

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _P.t2,
        ),
      ),
    );
  }

  Widget _cell(Widget child, {Alignment alignment = Alignment.centerLeft}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Align(alignment: alignment, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentData = ref.watch(recentTransaksiDashboardProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.border),
      ),
      child: recentData.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(color: _P.blue, strokeWidth: 2),
          ),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.error_rounded, color: _P.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gagal memuat: $err',
                  style: const TextStyle(color: _P.red, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        data: (listData) {
          if (listData.isEmpty) {
            return SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_rounded, color: _P.t3, size: 40),
                    const SizedBox(height: 10),
                    const Text(
                      'Belum ada transaksi masuk hari ini.',
                      style: TextStyle(color: _P.t2, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          final Map<int, dynamic> uniqueNotaMap = {};
          for (var item in listData) {
            if (!uniqueNotaMap.containsKey(item.idNota)) {
              uniqueNotaMap[item.idNota] = item;
            }
          }
          final finalDisplayList = uniqueNotaMap.values.toList();

          return Column(
            children: [
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(0.42),
                  1: FlexColumnWidth(2.55),
                  2: FlexColumnWidth(1.85),
                  3: FlexColumnWidth(1.05),
                  4: FlexColumnWidth(1.0),
                  5: FlexColumnWidth(1.0),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: _P.surfaceAlt),
                    children: [
                      _headerCell('#', align: TextAlign.center),
                      _headerCell('PETUGAS'),
                      _headerCell('TOKO'),
                      _headerCell('PLAT'),
                      _headerCell('HARGA', align: TextAlign.right),
                      _headerCell('STATUS', align: TextAlign.center),
                    ],
                  ),
                  ...List.generate(finalDisplayList.length, (i) {
                    final item = finalDisplayList[i];
                    final status = item.status.toString().toUpperCase();
                    final statusColor = _statusColor(status);

                    return TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: _P.border.withOpacity(0.7)),
                        ),
                      ),
                      children: [
                        _cell(
                          Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 11, color: _P.t2),
                          ),
                          alignment: Alignment.center,
                        ),
                        _cell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.namaPetugas,
                                softWrap: true,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _P.t1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    item.namaBarang,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _P.t2,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _P.blueL,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.kategoriBarang,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: _P.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _cell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.store_rounded,
                                size: 11,
                                color: _P.t3,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  item.namaToko,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: _P.t1,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _cell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _P.tealL,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _P.teal.withOpacity(0.2),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.nopolMobil,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _P.teal,
                                ),
                              ),
                            ),
                          ),
                          alignment: Alignment.center,
                        ),
                        _cell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  AppFormatters.rupiah(item.harga),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _P.t1,
                                  ),
                                ),
                              ),
                              Text(
                                'x${item.qty}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: _P.t3,
                                ),
                              ),
                            ],
                          ),
                          alignment: Alignment.centerRight,
                        ),
                        _cell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBackground(status),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: statusColor.withOpacity(0.25),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                status,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                          alignment: Alignment.center,
                        ),
                      ],
                    );
                  }),
                ],
              ),
              const Divider(height: 1, color: _P.border),
              InkWell(
                onTap: () => ctx.push('/riwayat-boss'),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: const BoxDecoration(
                    color: _P.blueL,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lihat semua pencatatan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _P.blue,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: _P.blue,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHART CARD
// ─────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final DashboardData data;
  const _ChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.only(right: 16, left: 8, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.border),
      ),
      child: LineChart(_buildChart()),
    );
  }

  LineChartData _buildChart() {
    final jutaan = data.belanja6Bulan.map((e) => e / 1_000_000).toList();
    final maxB = jutaan.isNotEmpty ? jutaan.reduce(max) : 0.0;
    final maxT = data.transaksi6Bulan.isNotEmpty
        ? data.transaksi6Bulan.reduce(max).toDouble()
        : 0.0;
    final highest = max(maxB, maxT);
    final maxY = highest > 0 ? highest + (highest * 0.2) : 10.0;
    double iv = (maxY / 5).ceilToDouble();
    if (iv == 0) iv = 1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: iv,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: _P.border, strokeWidth: 0.5, dashArray: [4, 6]),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => _P.t1,
          tooltipRoundedRadius: 8,
          getTooltipItems: (spots) => spots.map((spot) {
            final isBelanja = spot.barIndex == 0;
            return LineTooltipItem(
              isBelanja
                  ? AppFormatters.rupiah(spot.y * 1_000_000)
                  : '${spot.y.toInt()} Nota',
              TextStyle(
                color: isBelanja ? _P.blue : _P.teal,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ),
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
            getTitlesWidget: (value, _) {
              final i = value.toInt();
              if (i >= 0 && i < 6) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data.labelBulan[i],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _P.t2,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: iv,
            getTitlesWidget: (value, _) => Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 11, color: _P.t3),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 5,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(6, (i) => FlSpot(i.toDouble(), jutaan[i])),
          isCurved: true,
          preventCurveOverShooting: true,
          color: _P.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 4,
              color: _P.blue,
              strokeWidth: 2,
              strokeColor: _P.surface,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: _P.blue.withOpacity(0.06),
          ),
        ),
        LineChartBarData(
          spots: List.generate(
            6,
            (i) => FlSpot(i.toDouble(), data.transaksi6Bulan[i].toDouble()),
          ),
          isCurved: true,
          preventCurveOverShooting: true,
          color: _P.teal,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 4,
              color: _P.teal,
              strokeWidth: 2,
              strokeColor: _P.surface,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _P.t2,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────
// MODERN DRAWER — LIGHT
// ─────────────────────────────────────────────
class _ModernDrawer extends StatelessWidget {
  final WidgetRef ref;
  final BuildContext ctx;
  const _ModernDrawer({required this.ref, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _P.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            color: _P.bar,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pimpinan PT Lahir Barutama',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Eksekutif  ·  Read-Only',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              children: [
                _NavLabel('LAPORAN ANALISIS'),
                _NavTile(
                  icon: Icons.list_alt_rounded,
                  label: 'Riwayat Keseluruhan',
                  color: _P.indigo,
                  onTap: () {
                    Navigator.pop(context);
                    ctx.push('/riwayat-boss');
                  },
                ),
                _NavTile(
                  icon: Icons.assignment_ind_rounded,
                  label: 'Akuntabilitas Petugas',
                  color: _P.amber,
                  onTap: () {
                    Navigator.pop(context);
                    ctx.push('/log-petugas');
                  },
                ),
                _NavTile(
                  icon: Icons.store_rounded,
                  label: 'Rekap Hutang Toko',
                  color: _P.teal,
                  onTap: () {
                    Navigator.pop(context);
                    ctx.push('/rekap-hutang');
                  },
                ),
                const SizedBox(height: 8),
                Divider(color: _P.border, height: 1),
                const SizedBox(height: 8),
                _NavTile(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Cetak Laporan PDF',
                  color: _P.red,
                  onTap: () {
                    Navigator.pop(context);
                    ctx.push('/cetak-laporan');
                  },
                ),
              ],
            ),
          ),
          Divider(color: _P.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: _P.red,
                backgroundColor: _P.redL,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authRepositoryProvider).logout();
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  final String text;
  const _NavLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8, top: 4, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _P.t3,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NavTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _P.t1,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 16, color: _P.t3),
          ],
        ),
      ),
    ),
  );
}