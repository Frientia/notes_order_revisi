import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/providers/log_petugas_provider.dart';

class LogPetugasScreen extends ConsumerWidget {
  const LogPetugasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tanggalAktif = ref.watch(tanggalLogProvider);
    final logState = ref.watch(logPetugasListProvider);

    // Format label tanggal yang sedang aktif
    final String startText = DateFormat('dd MMM').format(tanggalAktif.start);
    final String endText = DateFormat('dd MMM yyyy').format(tanggalAktif.end);
    final String labelKalender = (tanggalAktif.start == tanggalAktif.end)
        ? DateFormat('dd MMM yyyy').format(tanggalAktif.start)
        : '$startText - $endText';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Akuntabilitas Petugas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BARIS FILTER: TOMBOL CEPAT & KALENDER ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      labelKalender,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    // TOMBOL KALENDER KUSTOM
                    IconButton(
                      icon: const Icon(
                        Icons.calendar_month,
                        color: Colors.indigo,
                      ),
                      tooltip: 'Pilih Tanggal Spesifik',
                      onPressed: () =>
                          _bukaKalender(context, ref, tanggalAktif),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // TOMBOL FILTER CEPAT (Hari, Minggu, Bulan)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickButton(
                        context,
                        ref,
                        'Hari Ini',
                        _getHariIni(),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickButton(
                        context,
                        ref,
                        'Minggu Ini',
                        _getMingguIni(),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickButton(
                        context,
                        ref,
                        'Bulan Ini',
                        _getBulanIni(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // --- DAFTAR PETUGAS ---
          Expanded(
            child: logState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Gagal memuat data:\n$err')),
              data: (listPetugas) {
                if (listPetugas.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada Pencatatan Pembelian pada periode ini.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listPetugas.length,
                  itemBuilder: (context, index) {
                    final petugas = listPetugas[index];

                    Color rankColor = Colors.grey.shade400;
                    if (index == 0) rankColor = Colors.amber;
                    if (index == 1) rankColor = Colors.blueGrey.shade300;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: rankColor,
                          foregroundColor: Colors.white,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          petugas.namaPetugas,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(petugas.emailPetugas),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${petugas.jumlahInput} Nota',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[800],
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: TOMBOL CEPAT ---
  Widget _buildQuickButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    DateTimeRange targetRange,
  ) {
    // Cek apakah tombol ini sedang aktif berdasarkan state tanggal saat ini
    final currentRange = ref.watch(tanggalLogProvider);
    final isSelected =
        currentRange.start == targetRange.start &&
        currentRange.end == targetRange.end;

    return ActionChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.blueGrey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: isSelected ? Colors.indigo : Colors.grey[200],
      onPressed: () {
        ref.read(tanggalLogProvider.notifier).state = targetRange;
      },
    );
  }

  // --- FUNGSI HELPER: KALENDER & RENTANG WAKTU ---
  Future<void> _bukaKalender(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange awal,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: awal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueGrey.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(tanggalLogProvider.notifier).state = picked;
    }
  }

  DateTimeRange _getHariIni() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  DateTimeRange _getMingguIni() {
    final now = DateTime.now();
    return DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  DateTimeRange _getBulanIni() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day),
    );
  }
}