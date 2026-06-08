import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';

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

  BarangKategori? _selectedKategoriBarang;
  MobilKategori? _selectedKategoriMobil;

  BarangModel? _selectedBarang;
  MobilModel? _selectedMobil;
  TokoModel? _selectedToko;
  
  final _qtyCtrl = TextEditingController();
  final _hargaEstimasiCtrl = TextEditingController();

  final Map<int, TextEditingController> _hargaRiilControllers = {};
  final Map<int, String> _statusPembayaranMap = {};
  final Map<int, Uint8List> _kwitansiBytesMap = {};
  final Map<int, String> _kwitansiNameMap = {};
  final Map<int, int> _kwitansiRefMap = {};

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

  void _showImageSourceOptions(BuildContext context, int idDetail) {
    final existingKeys = _kwitansiBytesMap.keys.where((k) => k != idDetail).toList();
    final hasPreviousImage = existingKeys.isNotEmpty;
    final primaryColor = Colors.teal.shade700;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Upload Kwitansi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.camera_alt, color: Colors.blue.shade600),
                ),
                title: const Text('Buka Kamera', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(idDetail, ImageSource.camera);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.photo_library, color: Colors.green.shade600),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(idDetail, ImageSource.gallery);
                },
              ),
              if (hasPreviousImage) ...[
                const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Divider()),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryColor.withAlpha(26), shape: BoxShape.circle),
                    child: Icon(Icons.file_copy_rounded, color: primaryColor),
                  ),
                  title: const Text('Gunakan Kwitansi Sebelumnya', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Menyalin referensi struk dari item di atas'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      final prevKey = existingKeys.last;
                      _kwitansiBytesMap[idDetail] = _kwitansiBytesMap[prevKey]!;
                      _kwitansiNameMap[idDetail] = _kwitansiNameMap[prevKey]!;
                      _kwitansiRefMap[idDetail] = _kwitansiRefMap[prevKey]!; 
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Referensi Kwitansi ditambahkan!'), backgroundColor: primaryColor));
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(int idDetail, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 70);

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _kwitansiBytesMap[idDetail] = bytes;
          _kwitansiNameMap[idDetail] = image.name;
          _kwitansiRefMap[idDetail] = idDetail; 
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

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
    for (var item in items) {
      final idDetail = item['id_detail_pencatatan'] as int;
      final hargaInput = double.tryParse(_hargaRiilControllers[idDetail]?.text ?? '0') ?? 0;
      
      if (hargaInput <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal! Harga riil item "${item['barang']['nama_barang']}" tidak boleh 0.'), backgroundColor: Colors.redAccent),
        );
        return; 
      }

      if (!_kwitansiBytesMap.containsKey(idDetail)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal! Kwitansi untuk item "${item['barang']['nama_barang']}" belum diupload.'), backgroundColor: Colors.red.shade600),
        );
        return; 
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final List<Map<String, dynamic>> finalDataPayload = [];

      for (var item in items) {
        final idDetail = item['id_detail_pencatatan'] as int;
        final hargaInput = double.tryParse(_hargaRiilControllers[idDetail]?.text ?? '') ?? 0;
        final statusInput = _statusPembayaranMap[idDetail] ?? 'SELESAI';
        
        final refId = _kwitansiRefMap[idDetail] ?? idDetail;
        final isMaster = refId == idDetail;

        finalDataPayload.add({
          'id_detail_pencatatan': idDetail,
          'harga_pembelian_barang': hargaInput,
          'status': statusInput,
          'kwitansi_ref_id': refId,
          
          'image_bytes': isMaster ? _kwitansiBytesMap[idDetail] : null, 
          'image_name': isMaster ? _kwitansiNameMap[idDetail] : null,
        });
      }

      final grandTotal = _hitungGrandTotal(items);

      await ref.read(transaksiRepositoryProvider).finalisasiTransaksi(
            idPencatatan: idDraft,
            grandTotal: grandTotal,
            finalItemsData: finalDataPayload,
          );
      
      ref.invalidate(transaksiDraftProvider);
      ref.invalidate(barangControllerProvider);

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

  Widget _buildSearchableDropdownWithShortcut<T>({
    required String label,
    required T? selectedItem,
    required List<T> items,
    required String Function(T) itemAsString,
    required bool Function(T, T) compareFn,
    required Function(T?) onChanged,
    required VoidCallback onAddPressed,
  }) {
    final primaryColor = Colors.teal.shade700;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownSearch<T>(
            selectedItem: selectedItem,
            items: (String filter, LoadProps? loadProps) {
              if (filter.isEmpty) return items;
              return items.where((element) {
                return itemAsString(element)
                    .toLowerCase()
                    .contains(filter.toLowerCase());
              }).toList();
            },
            itemAsString: itemAsString,
            compareFn: compareFn,
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Ketik untuk mencari...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
              menuProps: const MenuProps(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
              ),
            ),
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.grey.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                filled: true,
                fillColor: Colors.grey.shade100,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            onSelected: onChanged,
            validator: (val) => val == null ? 'Wajib dipilih' : null,
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onAddPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withAlpha(50)),
            ),
            child: Icon(Icons.add, color: primaryColor, size: 24),
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
    final primaryColor = Colors.teal.shade700;

    final filteredBarang = _selectedKategoriBarang == null 
        ? barangList 
        : barangList.where((b) => b.kategori == _selectedKategoriBarang).toList();
        
    final filteredMobil = _selectedKategoriMobil == null 
        ? mobilList 
        : mobilList.where((m) => m.kategori == _selectedKategoriMobil).toList();

    if (draftState.isLoading || _isSubmitting) {
      return Scaffold(backgroundColor: Colors.grey.shade50, body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimasi Grand Total', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                  Text(
                    AppFormatters.rupiah(_hitungGrandTotal(draftState.items)),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: draftState.items.isEmpty ? null : () => _eksekusiSelesai(draftState.idPencatatan!, draftState.items),
                child: const Text('SIMPAN TRANSAKSI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            elevation: 0,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: 120,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Form Pencatatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  Text('Draft #${draftState.idPencatatan}', style: TextStyle(fontSize: 12, color: Colors.teal.shade100, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12, left: 4),
                    child: Text('1. Rencana Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formItemKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<BarangKategori>(
                            value: _selectedKategoriBarang,
                            decoration: InputDecoration(
                              labelText: 'Filter Kategori Barang', 
                              labelStyle: TextStyle(color: Colors.grey.shade700),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: [
                              const DropdownMenuItem<BarangKategori>(value: null, child: Text('Semua Kategori')),
                              ...BarangKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))),
                            ],
                            onChanged: (v) => setState(() {
                              _selectedKategoriBarang = v;
                              _selectedBarang = null; 
                            }),
                          ),
                          const SizedBox(height: 16),

                          _buildSearchableDropdownWithShortcut<BarangModel>(
                            label: 'Cari / Pilih Barang',
                            selectedItem: _selectedBarang,
                            items: filteredBarang,
                            itemAsString: (b) => '${b.namaBarang} (${b.kategori?.label ?? "Umum"})',
                            compareFn: (a, b) => a.idBarang == b.idBarang,
                            onChanged: (v) => setState(() => _selectedBarang = v),
                            onAddPressed: () => _showAddBarangShortcut(context),
                          ),
                          const SizedBox(height: 24),

                          DropdownButtonFormField<MobilKategori>(
                            value: _selectedKategoriMobil,
                            decoration: InputDecoration(
                              labelText: 'Filter Kategori Mobil', 
                              labelStyle: TextStyle(color: Colors.grey.shade700),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: [
                              const DropdownMenuItem<MobilKategori>(value: null, child: Text('Semua Kategori')),
                              ...MobilKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))),
                            ],
                            onChanged: (v) => setState(() {
                              _selectedKategoriMobil = v;
                              _selectedMobil = null; 
                            }),
                          ),
                          const SizedBox(height: 16),

                          _buildSearchableDropdownWithShortcut<MobilModel>(
                            label: 'Cari / Pilih Alokasi Mobil',
                            selectedItem: _selectedMobil,
                            items: filteredMobil,
                            itemAsString: (m) => '${m.noPlat} (${m.kategori?.label ?? "-"})',
                            compareFn: (a, b) => a.idMobil == b.idMobil,
                            onChanged: (v) => setState(() => _selectedMobil = v),
                            onAddPressed: () => _showAddMobilShortcut(context),
                          ),
                          const SizedBox(height: 24),

                          _buildSearchableDropdownWithShortcut<TokoModel>(
                            label: 'Cari / Pilih Toko Tujuan',
                            selectedItem: _selectedToko,
                            items: tokoList,
                            itemAsString: (t) => t.namaToko,
                            compareFn: (a, b) => a.idToko == b.idToko,
                            onChanged: (v) => setState(() => _selectedToko = v),
                            onAddPressed: () => _showAddTokoShortcut(context),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Qty', 
                                    labelStyle: TextStyle(color: Colors.grey.shade700),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                                  ),
                                  validator: (v) => v!.isEmpty ? 'Wajib' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _hargaEstimasiCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Harga Estimasi (Rp)', 
                                    labelStyle: TextStyle(color: Colors.grey.shade700),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (_formItemKey.currentState!.validate() && _selectedBarang != null && _selectedMobil != null && _selectedToko != null) {
                                ref.read(transaksiDraftProvider.notifier).tambahItemKeDraft(
                                      idBarang: int.parse(_selectedBarang!.idBarang!),
                                      idMobil: int.parse(_selectedMobil!.idMobil!),
                                      idToko: int.parse(_selectedToko!.idToko!),
                                      qty: int.parse(_qtyCtrl.text),
                                      hargaEstimasi: double.tryParse(_hargaEstimasiCtrl.text) ?? 0,
                                    );
                                _qtyCtrl.clear();
                                _hargaEstimasiCtrl.clear();
                                setState(() {
                                  _selectedBarang = null;
                                  _selectedMobil = null;
                                  _selectedToko = null;
                                });
                              } else if (_selectedBarang == null || _selectedMobil == null || _selectedToko == null) {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Barang, Mobil, dan Toko!'), backgroundColor: Colors.orange));
                              }
                            },
                            icon: const Icon(Icons.add_shopping_cart, size: 20),
                            label: const Text('Masukan Ke Daftar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 12, left: 4),
                    child: Text('2. Realisasi Lapangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  ),
                  
                  if (draftState.items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Daftar belanja masih kosong', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final item = draftState.items[i];
                  final int idDetail = item['id_detail_pencatatan'];

                  if (!_hargaRiilControllers.containsKey(idDetail)) {
                    _hargaRiilControllers[idDetail] = TextEditingController(
                      text: item['harga_pembelian_barang'].toString() == '0.0' ? '' : item['harga_pembelian_barang'].toString(),
                    );
                    _statusPembayaranMap[idDetail] = item['status'] ?? 'SELESAI';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item['barang']?['nama_barang']} (${item['barang']?['kategori'] ?? "-"})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                ),
                              ),
                              InkWell(
                                onTap: () => ref.read(transaksiDraftProvider.notifier).hapusItemDariDraft(idDetail),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.directions_car, size: 16, color: primaryColor),
                              const SizedBox(width: 6),
                              Text('${item['mobil']?['no_plat']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 16),
                              Icon(Icons.store, size: 16, color: primaryColor),
                              const SizedBox(width: 6),
                              Text('${item['toko']?['nama_toko']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Text('Qty: ${item['qty']} unit', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, thickness: 1),
                          ),
                          
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _hargaRiilControllers[idDetail],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Harga Riil (Rp)', 
                                    labelStyle: TextStyle(color: Colors.grey.shade700),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    filled: true, 
                                    fillColor: Colors.grey.shade100
                                  ),
                                  onChanged: (value) => setState(() {}), 
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _statusPembayaranMap[idDetail],
                                  decoration: InputDecoration(
                                    labelText: 'Status', 
                                    labelStyle: TextStyle(color: Colors.grey.shade700),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    filled: true, 
                                    fillColor: Colors.grey.shade100
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'SELESAI', child: Text('CASH', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                    DropdownMenuItem(value: 'PENDING', child: Text('HUTANG', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                  ],
                                  onChanged: (v) => setState(() => _statusPembayaranMap[idDetail] = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _kwitansiBytesMap.containsKey(idDetail) ? Colors.green.shade700 : primaryColor,
                                    side: BorderSide(color: _kwitansiBytesMap.containsKey(idDetail) ? Colors.green.shade400 : primaryColor.withAlpha(100), width: 1.5),
                                    backgroundColor: _kwitansiBytesMap.containsKey(idDetail) ? Colors.green.shade50 : Colors.transparent,
                                    minimumSize: const Size(0, 48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _showImageSourceOptions(context, idDetail),
                                  icon: Icon(_kwitansiBytesMap.containsKey(idDetail) ? Icons.check_circle : Icons.camera_alt, size: 20),
                                  label: Text(
                                    _kwitansiBytesMap.containsKey(idDetail) ? 'Kwitansi Terunggah' : 'Upload Kwitansi',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              if (!_kwitansiBytesMap.containsKey(idDetail))
                                const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text('*Wajib', style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
                childCount: draftState.items.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _showAddBarangShortcut(BuildContext context) {
    final namaCtrl = TextEditingController();
    BarangKategori? shortcutSelectedKategori; 
    final primaryColor = Colors.teal.shade700;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Tambah Barang Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: namaCtrl, 
                decoration: InputDecoration(
                  labelText: 'Nama Barang', 
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ), 
                autofocus: true
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BarangKategori>(
                value: shortcutSelectedKategori,
                decoration: InputDecoration(
                  labelText: 'Kategori Barang', 
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
                items: BarangKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))).toList(),
                onChanged: (v) => setStateModal(() => shortcutSelectedKategori = v),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
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
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMobilShortcut(BuildContext context) {
    final platCtrl = TextEditingController();
    final tahunCtrl = TextEditingController();
    MobilKategori? selectedCat;
    final primaryColor = Colors.teal.shade700;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Tambah Mobil Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: platCtrl, 
                textCapitalization: TextCapitalization.characters, 
                decoration: InputDecoration(
                  labelText: 'No Plat', 
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ), 
                autofocus: true
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MobilKategori>(
                value: selectedCat,
                decoration: InputDecoration(
                  labelText: 'Kategori', 
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
                items: MobilKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))).toList(),
                onChanged: (v) => setStateModal(() => selectedCat = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tahunCtrl, 
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(
                  labelText: 'Tahun', 
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                )
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () async {
                if (platCtrl.text.isNotEmpty && selectedCat != null && tahunCtrl.text.isNotEmpty) {
                  final newMobil = MobilModel(noPlat: platCtrl.text.trim().toUpperCase(), kategori: selectedCat, tahun: int.parse(tahunCtrl.text));
                  await ref.read(mobilControllerProvider.notifier).addMobil(newMobil);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTokoShortcut(BuildContext context) {
    final namaCtrl = TextEditingController();
    final telponCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final primaryColor = Colors.teal.shade700;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tambah Toko Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: namaCtrl, 
              textCapitalization: TextCapitalization.words, 
              decoration: InputDecoration(
                labelText: 'Nama Toko', 
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              ), 
              autofocus: true
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: telponCtrl, 
              keyboardType: TextInputType.phone, 
              decoration: InputDecoration(
                labelText: 'No Telp', 
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              )
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: alamatCtrl, 
              textCapitalization: TextCapitalization.words, 
              decoration: InputDecoration(
                labelText: 'Alamat', 
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              )
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              if (namaCtrl.text.isNotEmpty && telponCtrl.text.isNotEmpty && alamatCtrl.text.isNotEmpty) {
                final newToko = TokoModel(
                  namaToko: namaCtrl.text.trim(),
                  noTelp: telponCtrl.text.trim(),
                  alamat: alamatCtrl.text.trim(),
                );
                await ref.read(tokoControllerProvider.notifier).addToko(newToko);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}