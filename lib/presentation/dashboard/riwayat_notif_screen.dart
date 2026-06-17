import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/providers/riwayat_notif_boss_provider.dart';
import '../../domain/providers/read_notif_provider.dart';
import '../../core/utils/formatters.dart';
import '../../domain/providers/riwayat_provider_boss.dart';

class RiwayatNotifScreen extends ConsumerStatefulWidget {
  const RiwayatNotifScreen({super.key});

  @override
  ConsumerState<RiwayatNotifScreen> createState() => _RiwayatNotifScreenState();
}

class _RiwayatNotifScreenState extends ConsumerState<RiwayatNotifScreen> {
  String _filterStatus = 'SEMUA'; 
  bool _isSortNewest = true; 

  @override
  Widget build(BuildContext context) {
    final listNotifAsync = ref.watch(riwayatNotifBossProvider);
    final allRiwayatState = ref.watch(riwayatDataProvider);
    final primaryColor = const Color(0xFF1E3A5F);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Kotak Masuk', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          listNotifAsync.when(
            data: (listData) {
              if (listData.isEmpty) return const SizedBox();

              final List<int> unreadIds = listData
                  .where((d) => d['is_read'] != true)
                  .map((d) => d['id_notif'] as int)
                  .toList();

              final bool hasUnread = unreadIds.isNotEmpty;

              return TextButton.icon(
                onPressed: hasUnread
                    ? () async {
                        await ref.read(readNotificationsProvider).markAllAsRead(unreadIds);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Semua notifikasi telah ditandai dibaca'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      }
                    : null,
                icon: Icon(
                  Icons.done_all_rounded,
                  color: hasUnread ? Colors.white : Colors.white30,
                  size: 18,
                ),
                label: Text(
                  'Tandai Semua',
                  style: TextStyle(
                    color: hasUnread ? Colors.white : Colors.white30,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', 'SEMUA', primaryColor),
                        const SizedBox(width: 8),
                        _buildFilterChip('Belum Dibaca', 'UNREAD', Colors.blue.shade700),
                        const SizedBox(width: 8),
                        _buildFilterChip('Hutang', 'HUTANG', Colors.orange.shade700),
                        const SizedBox(width: 8),
                        _buildFilterChip('Lunas', 'LUNAS', Colors.green.shade700),
                        const SizedBox(width: 8),
                        _buildFilterChip('Sudah Dibaca', 'READ', Colors.grey.shade700),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                InkWell(
                  onTap: () => setState(() => _isSortNewest = !_isSortNewest),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          _isSortNewest ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isSortNewest ? 'Terbaru' : 'Terlama',
                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: listNotifAsync.when(
              data: (listData) {
                var filteredList = List<Map<String, dynamic>>.from(listData);

                if (_filterStatus == 'HUTANG') {
                  filteredList = filteredList.where((item) => item['tipe_notif'] == 'PENCATATAN_HUTANG' || item['tipe_notif'] == 'REMINDER_HUTANG').toList();
                } else if (_filterStatus == 'LUNAS') {
                  filteredList = filteredList.where((item) => item['tipe_notif'] == 'PENCATATAN' || item['tipe_notif'] == 'PELUNASAN').toList();
                } else if (_filterStatus == 'UNREAD') {
                  filteredList = filteredList.where((item) => item['is_read'] != true).toList();
                } else if (_filterStatus == 'READ') {
                  filteredList = filteredList.where((item) => item['is_read'] == true).toList();
                }

                filteredList.sort((a, b) {
                  final dateA = a['created_at'] != null ? DateTime.parse(a['created_at']) : DateTime.now();
                  final dateB = b['created_at'] != null ? DateTime.parse(b['created_at']) : DateTime.now();
                  return _isSortNewest ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
                });

                if (filteredList.isEmpty) {
                  String emptyMessage = 'Belum ada notifikasi masuk';
                  if (_filterStatus == 'LUNAS') emptyMessage = 'Tidak ada notifikasi transaksi lunas';
                  if (_filterStatus == 'HUTANG') emptyMessage = 'Tidak ada notifikasi terkait hutang';
                  if (_filterStatus == 'UNREAD') emptyMessage = 'Tidak ada notifikasi baru';
                  if (_filterStatus == 'READ') emptyMessage = 'Belum ada notifikasi yang dibaca';

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          emptyMessage,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final data = filteredList[index];
                    final int idNotif = data['id_notif'];
                    final int? idPencatatan = data['id_pencatatan'];
                    final bool isRead = data['is_read'] == true;
                    final String tipeNotif = data['tipe_notif'] ?? 'PENCATATAN';
                    
                    final bool isHutang = tipeNotif == 'PENCATATAN_HUTANG' || tipeNotif == 'REMINDER_HUTANG';
                    final bool isReminder = tipeNotif == 'REMINDER_HUTANG';
                    
                    DateTime tgl = DateTime.now();
                    if (data['created_at'] != null) {
                      tgl = DateTime.parse(data['created_at']).toLocal();
                    }
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.grey.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isRead ? [] : [
                          BoxShadow(color: Colors.grey.withAlpha(20), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                        border: Border.all(color: isRead ? Colors.grey.shade300 : (isHutang ? (isReminder ? Colors.red.shade200 : Colors.orange.shade200) : Colors.blue.shade100)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: isRead ? Colors.grey.shade300 : (isReminder ? Colors.red.shade50 : (isHutang ? Colors.orange.shade50 : Colors.blue.shade50)),
                          radius: 24,
                          child: Icon(
                            isRead ? Icons.drafts : (isReminder ? Icons.notification_important_rounded : (isHutang ? Icons.warning_amber_rounded : Icons.mark_email_unread)), 
                            color: isRead ? Colors.grey.shade600 : (isReminder ? Colors.red.shade600 : (isHutang ? Colors.orange.shade700 : Colors.blue.shade600)), 
                            size: 24
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['judul'] ?? 'Notifikasi Sistem',
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  fontSize: 15,
                                  color: isRead ? Colors.grey.shade600 : (isReminder ? Colors.red.shade900 : (isHutang ? Colors.orange.shade900 : Colors.black87)),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isHutang ? (isReminder ? Colors.red.shade100 : Colors.orange.shade100) : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isHutang ? (isReminder ? 'URGENT' : 'HUTANG') : 'LUNAS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isHutang ? (isReminder ? Colors.red.shade800 : Colors.orange.shade800) : Colors.green.shade800,
                                ),
                              ),
                            )
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['pesan'] ?? '',
                                style: TextStyle(fontSize: 13, color: isRead ? Colors.grey.shade500 : Colors.grey.shade800, height: 1.4),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: isRead ? Colors.grey.shade400 : Colors.blueGrey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy • HH:mm').format(tgl),
                                    style: TextStyle(
                                      fontSize: 12, color: isRead ? Colors.grey.shade400 : Colors.blueGrey.shade600,
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          if (!isRead) {
                            ref.read(readNotificationsProvider).markAsRead(idNotif);
                          }
                          
                          if (idPencatatan == null) return;
                          
                          final listSemuaRiwayat = allRiwayatState.value ?? [];
                          try {
                            final itemAsli = listSemuaRiwayat.firstWhere((item) => item.idNota == idPencatatan);
                            _showKwitansiDialog(context, ref, itemAsli);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Memuat detail... Silakan coba lagi atau cek menu Riwayat Keseluruhan.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Terjadi kesalahan: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color activeColor) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showKwitansiDialog(BuildContext context, WidgetRef ref, RiwayatTransaksi item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('Detail Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 24),

                  _detailRow('ID Nota / Detail:', '#${item.idNota} / #${item.idDetail}'),
                  _detailRow('Tanggal:', DateFormat('dd MMM yyyy, HH:mm').format(item.tanggal)),
                  _detailRow('Barang:', '${item.namaBarang} (${item.kategoriBarang})', isBold: true),
                  _detailRow('Toko:', item.namaToko),
                  _detailRow('Mobil:', '${item.nopolMobil} (${item.kategoriMobil})'),
                  _detailRow('Petugas:', item.namaPetugas),
                  _detailRow(
                    'Status:',
                    item.status == 'PENDING' ? 'HUTANG' : 'LUNAS',
                    color: item.status == 'PENDING' ? Colors.orange : Colors.green,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        AppFormatters.rupiah(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[900],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold || color != null ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}