import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/barang_model.dart';
import '../../data/models/mobil_model.dart';
import '../../data/models/toko_model.dart';
import '../../data/repositories/transaksi_repository.dart';
import '../../domain/providers/barang_provider.dart';
import '../../domain/providers/mobil_provider.dart';
import '../../domain/providers/toko_provider.dart';
import '../../domain/providers/transaksi_draft_provider.dart';
import '../../core/utils/formatters.dart';

class FormPencatatanScreen extends ConsumerStatefulWidget {
  const FormPencatatanScreen({super.key});

  @override
  ConsumerState<FormPencatatanScreen> createState() => _FormPencatatanScreenState();
}

class _FormPencatatanScreenState extends ConsumerState<FormPencatatanScreen> {
  final _formItemKey = GlobalKey<FormState>();

  // State Filter Kategori
  BarangKategori? _selectedKategoriBarang;
  MobilKategori? _selectedKategoriMobil;

  // State Input Rencana
  String? _selectedIdBarang;
  String? _selectedIdMobil;
  String? _selectedIdToko;
  final _qtyCtrl = TextEditingController();
  final _hargaEstimasiCtrl = TextEditingController();

  // State Input Lapangan (Riil)
  final Map<int, TextEditingController> _hargaRiilControllers = {};
  final Map<int, String> _statusPembayaranMap = {};
  final Map<int, Uint8List> _kwitansiBytesMap = {};
  final Map<int, String> _kwitansiNameMap = {};

  bool _isSubmitting = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _hargaEstimasiCtrl.dispose();
    for (var ctrl in _hargaRiilControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickKwitansiPerItem(int idDetail) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _kwitansiBytesMap[idDetail] = bytes;
        _kwitansiNameMap[idDetail] = pickedFile.name;
      });
    }
  }

  // Kalkulasi Realtime yang lebih aman
  double _hitungGrandTotal(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var item in items) {
      final idDetail = item['id_detail_pencatatan'] as int;
      final inputText = _hargaRiilControllers[idDetail]?.text ?? '';
      final harga = inputText.isNotEmpty 
          ? (double.tryParse(inputText) ?? 0) 
          : (double.tryParse(item['harga_pembelian_barang'].toString()) ?? 0);
      final qty = item['qty'] as int;
      total += (qty * harga);
    }
    return total;
  }

  Future<void> _eksekusiSelesai(int idDraft, List<Map<String, dynamic>> items) async {
    // 1. VALIDASI KETAT SEBELUM FINALISASI
    for (var item in items) {
      final idDetail = item['id_detail_pencatatan'] as int;
      final hargaInput = double.tryParse(_hargaRiilControllers[idDetail]?.text ?? '0') ?? 0;
      
      if (hargaInput <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal! Harga riil pada item "${item['barang']['nama_barang']}" tidak boleh 0 atau kosong.'), backgroundColor: Colors.red),
        );
        return; 
      }

      if (!_kwitansiBytesMap.containsKey(idDetail)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal! Kwitansi untuk item "${item['barang']['nama_barang']}" belum diupload.'), backgroundColor: Colors.red),
        );
        return; 
      }
    }

    // 2. EKSEKUSI JIKA SEMUA VALID
    setState(() => _isSubmitting = true);
    try {
      final List<Map<String, dynamic>> finalDataPayload = [];

      for (var item in items) {
        final idDetail = item['id_detail_pencatatan'] as int;
        final hargaInput = double.tryParse(_hargaRiilControllers[idDetail]?.text ?? '') ?? 0;
        final statusInput = _statusPembayaranMap[idDetail] ?? 'SELESAI';

        finalDataPayload.add({
          'id_detail_pencatatan': idDetail,
          'harga_pembelian_barang': hargaInput,
          'status': statusInput,
          'image_bytes': _kwitansiBytesMap[idDetail],
          'image_name': _kwitansiNameMap[idDetail],
        });
      }

      final grandTotal = _hitungGrandTotal(items);

      await ref.read(transaksiRepositoryProvider).finalisasiTransaksi(
            idPencatatan: idDraft,
            grandTotal: grandTotal,
            finalItemsData: finalDataPayload,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi Sukses Disimpan ke Riwayat!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // --- WIDGET HELPER UNTUK DROPDOWN + SHORTCUT ---
  Widget _buildDropdownWithShortcut<T>({
    required String label,
    required T? value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required VoidCallback onAddPressed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<T>(
            value: value,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              prefixIcon: Icon(icon, size: 20),
              isDense: true,
            ),
            items: items,
            onChanged: onChanged,
            validator: (val) => val == null ? 'Wajib' : null,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            tooltip: 'Tambah Data Baru',
            onPressed: onAddPressed,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final draftState = ref.watch(transaksiDraftProvider);
    
    final barangList = ref.watch(barangControllerProvider).valueOrNull ?? [];
    final mobilList = ref.watch(mobilControllerProvider).valueOrNull ?? [];
    final tokoList = ref.watch(tokoControllerProvider).valueOrNull ?? [];

    final filteredBarang = _selectedKategoriBarang == null 
        ? barangList 
        : barangList.where((b) => b.kategori == _selectedKategoriBarang).toList();
        
    final filteredMobil = _selectedKategoriMobil == null 
        ? mobilList 
        : mobilList.where((m) => m.kategori == _selectedKategoriMobil).toList();

    if (draftState.isLoading || _isSubmitting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Form Pencatatan (Draft #${draftState.idPencatatan})')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- FASE 1: FORM INPUT RENCANA ---
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formItemKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('1. Tambah Rencana Kebutuhan Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Divider(),
                    
                    DropdownButtonFormField<BarangKategori>(
                      value: _selectedKategoriBarang,
                      decoration: const InputDecoration(labelText: 'Filter Kategori Barang', isDense: true, border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<BarangKategori>(value: null, child: Text('Semua Kategori')),
                        ...BarangKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedKategoriBarang = v;
                        _selectedIdBarang = null; 
                      }),
                    ),
                    const SizedBox(height: 16),

                    // FIX 1: Tambahkan tanda seru (!) di b.idBarang!
                    _buildDropdownWithShortcut<String>(
                      label: 'Pilih Barang',
                      icon: Icons.inventory_2,
                      value: _selectedIdBarang,
                      items: filteredBarang.map((b) => DropdownMenuItem(
                        value: b.idBarang!, // <--- Tanda seru pengaman
                        child: Text('${b.namaBarang} (${b.kategori?.label ?? "Umum"})') // Teks Enum Cantik
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedIdBarang = v),
                      onAddPressed: () => _showAddBarangShortcut(context),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<MobilKategori>(
                      value: _selectedKategoriMobil,
                      decoration: const InputDecoration(labelText: 'Filter Kategori Mobil', isDense: true, border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<MobilKategori>(value: null, child: Text('Semua Kategori')),
                        ...MobilKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedKategoriMobil = v;
                        _selectedIdMobil = null; 
                      }),
                    ),
                    const SizedBox(height: 12),

                    // FIX 2: Tambahkan tanda seru (!) di m.idMobil!
                    _buildDropdownWithShortcut<String>(
                      label: 'Pilih Alokasi Mobil',
                      icon: Icons.directions_car,
                      value: _selectedIdMobil,
                      items: filteredMobil.map((m) => DropdownMenuItem(
                        value: m.idMobil!, // <--- Tanda seru pengaman
                        child: Text('${m.noPlat} (${m.kategori?.label ?? "-"})')
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedIdMobil = v),
                      onAddPressed: () => _showAddMobilShortcut(context),
                    ),
                    const SizedBox(height: 16),

                    // FIX 3: Tambahkan tanda seru (!) di t.idToko!
                    _buildDropdownWithShortcut<String>(
                      label: 'Pilih Toko Tujuan',
                      icon: Icons.store,
                      value: _selectedIdToko,
                      items: tokoList.map((t) => DropdownMenuItem(
                        value: t.idToko!, // <--- Tanda seru pengaman
                        child: Text(t.namaToko)
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedIdToko = v),
                      onAddPressed: () => _showAddTokoShortcut(context),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true),
                            validator: (v) => v!.isEmpty ? 'Wajib' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _hargaEstimasiCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Harga Estimasi (Rp)', border: OutlineInputBorder(), isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_formItemKey.currentState!.validate()) {
                          ref.read(transaksiDraftProvider.notifier).tambahItemKeDraft(
                                idBarang: int.parse(_selectedIdBarang!),
                                idMobil: int.parse(_selectedIdMobil!),
                                idToko: int.parse(_selectedIdToko!),
                                qty: int.parse(_qtyCtrl.text),
                                hargaEstimasi: double.tryParse(_hargaEstimasiCtrl.text) ?? 0,
                              );
                          _qtyCtrl.clear();
                          _hargaEstimasiCtrl.clear();
                          setState(() {
                            _selectedIdBarang = null;
                            _selectedIdMobil = null;
                            _selectedIdToko = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Masukkan ke Database Draft'),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- FASE 2: DAFTAR EKSEKUSI DI LAPANGAN ---
          const Text('2. Daftar Belanja & Pengisian Riil Lapangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: draftState.items.length,
            itemBuilder: (ctx, i) {
              final item = draftState.items[i];
              final int idDetail = item['id_detail_pencatatan'];

              if (!_hargaRiilControllers.containsKey(idDetail)) {
                _hargaRiilControllers[idDetail] = TextEditingController(
                  text: item['harga_pembelian_barang'].toString() == '0.0' ? '' : item['harga_pembelian_barang'].toString(),
                );
                _statusPembayaranMap[idDetail] = item['status'] ?? 'SELESAI';
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              // Memunculkan nama barang beserta kategorinya di daftar belanja
                              '${item['barang']?['nama_barang']} (${item['barang']?['kategori'] ?? "-"})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => ref.read(transaksiDraftProvider.notifier).hapusItemDariDraft(idDetail),
                          )
                        ],
                      ),
                      Text('Mobil: ${item['mobil']?['no_plat']} | Toko: ${item['toko']?['nama_toko']}'),
                      Text('Jumlah Dibeli: ${item['qty']} unit', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                      const Divider(),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _hargaRiilControllers[idDetail],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Harga Bayar Riil (Rp)', isDense: true, filled: true, fillColor: Colors.white),
                              onChanged: (value) => setState(() {}), 
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _statusPembayaranMap[idDetail],
                              decoration: const InputDecoration(labelText: 'Metode', isDense: true, filled: true, fillColor: Colors.white),
                              items: const [
                                DropdownMenuItem(value: 'SELESAI', child: Text('CASH')),
                                DropdownMenuItem(value: 'PENDING', child: Text('HUTANG')),
                              ],
                              onChanged: (v) => setState(() => _statusPembayaranMap[idDetail] = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
                            onPressed: () => _pickKwitansiPerItem(idDetail),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: Text(_kwitansiBytesMap.containsKey(idDetail) ? 'Ubah Foto Kwitansi' : 'Foto Kwitansi Riil'),
                          ),
                          if (_kwitansiBytesMap.containsKey(idDetail))
                            const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18), Text(' OK', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))])
                          else
                            const Text('*Wajib Diupload', style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),

          if (draftState.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Belum ada item rencana belanja di draft ini.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
            ),

          const Divider(thickness: 2, height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ESTIMASI GRAND TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                AppFormatters.rupiah(_hitungGrandTotal(draftState.items)),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: draftState.items.isEmpty ? null : () => _eksekusiSelesai(draftState.idPencatatan!, draftState.items),
            child: const Text('SELESAIKAN & SIMPAN SEMUA TRANSAKSI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================= MODAL SHORTCUTS ================= //

  void _showAddBarangShortcut(BuildContext context) {
    final namaCtrl = TextEditingController();
    BarangKategori? shortcutSelectedKategori; 

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          title: const Text('Tambah Barang Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Barang', border: OutlineInputBorder()), autofocus: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<BarangKategori>(
                value: shortcutSelectedKategori,
                decoration: const InputDecoration(labelText: 'Kategori Barang', border: OutlineInputBorder()),
                items: BarangKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))).toList(),
                onChanged: (v) => setStateModal(() => shortcutSelectedKategori = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (namaCtrl.text.isNotEmpty && shortcutSelectedKategori != null) {
                  final newBarang = BarangModel(
                    namaBarang: namaCtrl.text.trim(), 
                    kategori: shortcutSelectedKategori,
                  );
                  await ref.read(barangControllerProvider.notifier).addBarang(newBarang);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMobilShortcut(BuildContext context) {
    final platCtrl = TextEditingController();
    MobilKategori? selectedCat;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          title: const Text('Tambah Mobil Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: platCtrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'No Plat', border: OutlineInputBorder()), autofocus: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<MobilKategori>(
                value: selectedCat,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                items: MobilKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))).toList(),
                onChanged: (v) => setStateModal(() => selectedCat = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (platCtrl.text.isNotEmpty && selectedCat != null) {
                  final newMobil = MobilModel(noPlat: platCtrl.text.trim().toUpperCase(), kategori: selectedCat);
                  await ref.read(mobilControllerProvider.notifier).addMobil(newMobil);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTokoShortcut(BuildContext context) {
    final namaCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Toko Baru'),
        content: TextFormField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Toko', border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (namaCtrl.text.isNotEmpty) {
                final newToko = TokoModel(namaToko: namaCtrl.text.trim());
                await ref.read(tokoControllerProvider.notifier).addToko(newToko);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}