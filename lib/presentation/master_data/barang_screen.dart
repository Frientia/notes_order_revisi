import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/barang_model.dart';
import '../../data/models/kategori_model.dart';
import '../../domain/providers/barang_provider.dart';
import '../../domain/providers/kategori_provider.dart';
import '../../domain/providers/mobil_provider.dart';

class BarangScreen extends ConsumerStatefulWidget {
  const BarangScreen({super.key});

  @override
  ConsumerState<BarangScreen> createState() => _BarangScreenState();
}

class _BarangScreenState extends ConsumerState<BarangScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // === VARIABEL FILTER ADVANCED ===
  int? _filterIdKategoriBarang;
  int? _filterIdKategoriMobil;
  String _sortStock = 'Normal'; // 'Normal', 'Sedikit', 'Banyak'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barangState = ref.watch(barangControllerProvider);
    final primaryColor = const Color(0xFF1E3A5F);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 48, bottom: 16),
              title: Text('Master Data Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                children: [
                  _buildSearchBar(primaryColor),
                  const SizedBox(height: 12),
                  _buildFilterInfoRow(primaryColor), // Menampilkan status filter aktif
                ],
              ),
            ),
          ),
          barangState.when(
            data: (listBarang) {
              // === LOGIKA FILTER & SORTING ULTIMATE ===
              var filteredList = listBarang.where((barang) {
                // 1. Search Query
                final query = _searchQuery.toLowerCase();
                final matchSearch = barang.namaBarang.toLowerCase().contains(query) ||
                    (barang.kategori?.namaKategori.toLowerCase().contains(query) ?? false);
                
                // 2. Filter Kategori Barang
                final matchKatBarang = _filterIdKategoriBarang == null || barang.idKategori == _filterIdKategoriBarang;
                
                // 3. Filter Kategori Mobil (Mencari apakah ada mobil di barang ini yang cocok dengan filter)
                final matchKatMobil = _filterIdKategoriMobil == null || 
                    (barang.kecocokanMobil != null && barang.kecocokanMobil!.any((m) => m.idKategori == _filterIdKategoriMobil));

                return matchSearch && matchKatBarang && matchKatMobil;
              }).toList();

              // 4. Sorting Stok
              if (_sortStock == 'Sedikit') {
                filteredList.sort((a, b) => a.stock.compareTo(b.stock));
              } else if (_sortStock == 'Banyak') {
                filteredList.sort((a, b) => b.stock.compareTo(a.stock));
              }
              // ==========================================

              if (listBarang.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(Icons.inventory_2_outlined, 'Belum Ada Data', 'Data barang Anda masih kosong.'),
                );
              }

              if (filteredList.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(Icons.search_off_rounded, 'Tidak Ditemukan', 'Ubah kriteria pencarian atau filter Anda.'),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _BarangListItem(barang: filteredList[index]),
                    childCount: filteredList.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: primaryColor))),
            error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Terjadi kesalahan:\n$error'))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormBottomSheet(context),
        backgroundColor: primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Barang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Baris Info & Tombol Filter
  Widget _buildFilterInfoRow(Color primaryColor) {
    bool isFilterActive = _filterIdKategoriBarang != null || _filterIdKategoriMobil != null || _sortStock != 'Normal';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isFilterActive ? 'Filter aktif' : 'Semua Data',
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        ActionChip(
          backgroundColor: isFilterActive ? primaryColor.withAlpha(20) : Colors.white,
          side: BorderSide(color: isFilterActive ? primaryColor : Colors.grey.shade300),
          label: Text('Filter Data', style: TextStyle(color: isFilterActive ? primaryColor : Colors.black87, fontWeight: FontWeight.bold)),
          avatar: Icon(Icons.tune_rounded, size: 16, color: isFilterActive ? primaryColor : Colors.black87),
          onPressed: () => _showAdvancedFilterDialog(context),
        ),
      ],
    );
  }

  // Dialog Filter Advanced
  void _showAdvancedFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter & Urutkan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                const Text('Urutkan Stok', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Normal', 'Sedikit', 'Banyak'].map((sort) {
                    final isSelected = _sortStock == sort;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(sort),
                      onSelected: (val) {
                        setStateDialog(() => _sortStock = sort);
                        setState(() {}); // Update main screen
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                const Text('Kategori Barang', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ref.watch(kategoriBarangProvider).when(
                  data: (kategoriList) => DropdownButtonFormField<int?>(
                    value: _filterIdKategoriBarang,
                    decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Kategori')),
                      ...kategoriList.map((k) => DropdownMenuItem(value: k.idKategori, child: Text(k.namaKategori))),
                    ],
                    onChanged: (val) {
                      setStateDialog(() => _filterIdKategoriBarang = val);
                      setState(() {});
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Gagal muat kategori'),
                ),
                const SizedBox(height: 16),

                const Text('Barang Untuk Kategori Mobil', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ref.watch(kategoriMobilProvider).when(
                  data: (kategoriList) => DropdownButtonFormField<int?>(
                    value: _filterIdKategoriMobil,
                    decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Mobil')),
                      ...kategoriList.map((k) => DropdownMenuItem(value: k.idKategori, child: Text(k.namaKategori))),
                    ],
                    onChanged: (val) {
                      setStateDialog(() => _filterIdKategoriMobil = val);
                      setState(() {});
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Gagal muat kategori'),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setStateDialog(() {
                            _filterIdKategoriBarang = null;
                            _filterIdKategoriMobil = null;
                            _sortStock = 'Normal';
                          });
                          setState(() {});
                        },
                        child: const Text('Reset Filter'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Terapkan'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 8))]),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari nama barang...',
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF1E3A5F).withAlpha(20), shape: BoxShape.circle), child: Icon(icon, size: 64, color: const Color(0xFF1E3A5F).withAlpha(80))),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _BarangListItem extends ConsumerWidget {
  final BarangModel barang;
  const _BarangListItem({required this.barang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = const Color(0xFF1E3A5F);
    final isLowStock = barang.stock < 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 54, width: 54,
              decoration: BoxDecoration(color: primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(barang.namaBarang.isNotEmpty ? barang.namaBarang[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: primaryColor)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(barang.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(barang.kategori?.namaKategori ?? 'Belum ada kategori', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: isLowStock ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text('Stok: ${barang.stock}', style: TextStyle(color: isLowStock ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      if (barang.kecocokanMobil != null && barang.kecocokanMobil!.isNotEmpty)
                        InkWell(
                          onTap: () => _tampilDetailMobil(context, barang),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_car_rounded, size: 14, color: Colors.orange.shade800),
                                const SizedBox(width: 4),
                                Text('${barang.kecocokanMobil!.length} Mobil', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Belum Diatur', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                InkWell(
                  onTap: () => _showFormBottomSheet(context, barang: barang),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.edit_rounded, color: Colors.blue.shade600, size: 20)),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _confirmDelete(context, ref, barang),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 20)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BarangModel barang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus data "${barang.namaBarang}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(barangControllerProvider.notifier).deleteBarang(barang.idBarang!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// Fungsi Modal Detail Mobil
void _tampilDetailMobil(BuildContext context, BarangModel barang) {
  showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            Text('Kecocokan: ${barang.namaBarang}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Barang ini dapat dipasang pada mobil-mobil berikut:', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8, runSpacing: 12,
              children: barang.kecocokanMobil!.map((mobil) {
                return Chip(
                  avatar: const Icon(Icons.directions_car_outlined, size: 16, color: Colors.white),
                  label: Text(mobil.noPlat, style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF1E3A5F),
                  labelStyle: const TextStyle(color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))),
          ],
        ),
      );
    },
  );
}

void _showFormBottomSheet(BuildContext context, {BarangModel? barang}) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (ctx) => _BarangFormSheet(barang: barang),
  );
}

class _BarangFormSheet extends ConsumerStatefulWidget {
  final BarangModel? barang;
  const _BarangFormSheet({this.barang});

  @override
  ConsumerState<_BarangFormSheet> createState() => _BarangFormSheetState();
}

class _BarangFormSheetState extends ConsumerState<_BarangFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _stockCtrl;
  
  KategoriModel? _selectedKategori;
  List<int> _selectedMobilIds = []; 
  bool _isSubmitting = false;

  String _searchMobilQuery = '';
  int? _filterKatMobilDiForm;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.barang?.namaBarang);
    _stockCtrl = TextEditingController(text: widget.barang?.stock.toString() ?? '0');
    _selectedKategori = widget.barang?.kategori;
    
    if (widget.barang != null && widget.barang!.kecocokanMobil != null) {
      _selectedMobilIds = widget.barang!.kecocokanMobil!.map((m) => m.idMobil!).toList();
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);

    final newBarang = BarangModel(
      idBarang: widget.barang?.idBarang,
      namaBarang: _namaCtrl.text.trim(),
      idKategori: _selectedKategori!.idKategori,
      stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
    );

    try {
      if (widget.barang != null) {
        await ref.read(barangControllerProvider.notifier).updateBarang(newBarang, listIdMobilCocok: _selectedMobilIds);
      } else {
        await ref.read(barangControllerProvider.notifier).addBarang(newBarang, listIdMobilCocok: _selectedMobilIds);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.barang != null;
    final primaryColor = const Color(0xFF1E3A5F);
    final height = MediaQuery.of(context).size.height * 0.9; 

    return Container(
      height: height,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 12),
      child: Column(
        children: [
          Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          Text(isEdit ? 'Edit Data Barang' : 'Tambah Barang Baru', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _namaCtrl, textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: 'Nama Barang', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildKategoriDropdown(primaryColor),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockCtrl, keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Stok Awal', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text('Kecocokan Mobil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            onChanged: (val) => setState(() => _searchMobilQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Cari Plat...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: ref.watch(kategoriMobilProvider).when(
                            data: (kategoriList) => DropdownButtonFormField<int?>(
                              value: _filterKatMobilDiForm,
                              decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Semua Mobil')),
                                ...kategoriList.map((k) => DropdownMenuItem(value: k.idKategori, child: Text(k.namaKategori, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (val) => setState(() => _filterKatMobilDiForm = val),
                            ),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: _buildMobilChecklist(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _isSubmitting ? null : _submitForm,
              child: _isSubmitting ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Barang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriDropdown(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: ref.watch(kategoriBarangProvider).when(
            data: (listKategori) => DropdownButtonFormField<KategoriModel>(
              value: _selectedKategori,
              decoration: InputDecoration(labelText: 'Kategori', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              items: listKategori.map((k) => DropdownMenuItem(value: k, child: Text(k.namaKategori))).toList(),
              onChanged: (val) => setState(() => _selectedKategori = val),
              validator: (val) => val == null ? 'Pilih kategori' : null,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 8),
        // Tombol Quick Add Kategori
        InkWell(
          onTap: () => _tambahKategoriBaru(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMobilChecklist() {
    return ref.watch(mobilControllerProvider).when(
      data: (listMobil) {
        final filteredMobil = listMobil.where((mobil) {
          final matchSearch = mobil.noPlat.toLowerCase().contains(_searchMobilQuery.toLowerCase());
          final matchKat = _filterKatMobilDiForm == null || mobil.idKategori == _filterKatMobilDiForm;
          return matchSearch && matchKat;
        }).toList();

        if (listMobil.isEmpty) return const Center(child: Text('Belum ada data mobil.'));
        if (filteredMobil.isEmpty) return const Center(child: Text('Mobil tidak ditemukan.'));

        return ListView.builder(
          itemCount: filteredMobil.length,
          itemBuilder: (context, index) {
            final mobil = filteredMobil[index];
            final isChecked = _selectedMobilIds.contains(mobil.idMobil);
            return CheckboxListTile(
              title: Text(mobil.noPlat, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(mobil.kategori?.namaKategori ?? 'Tanpa Kategori', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              value: isChecked,
              activeColor: const Color(0xFF1E3A5F),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedMobilIds.add(mobil.idMobil!);
                  } else {
                    _selectedMobilIds.remove(mobil.idMobil);
                  }
                });
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Gagal memuat mobil.')),
    );
  }

  // Fungsi Dialog untuk Quick Add Kategori Mobil
  void _tambahKategoriBaru(BuildContext context) {
    final txtKategori = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategori Barang Baru'),
        content: TextField(
          controller: txtKategori,
          decoration: const InputDecoration(hintText: 'Misal: Kampas Rem, Oli Mesin, dll.'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (txtKategori.text.trim().isEmpty) return;
              try {
                // Simpan ke DB lewat repository
                final repo = ref.read(kategoriRepositoryProvider);
                await repo.addKategori('kategori_barang', txtKategori.text.trim());
                
                // Refresh provider agar dropdown terupdate
                ref.invalidate(kategoriBarangProvider);
                
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori berhasil ditambahkan!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}