import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/barang_model.dart';
import '../../domain/providers/barang_provider.dart';

class BarangScreen extends ConsumerStatefulWidget {
  const BarangScreen({super.key});

  @override
  ConsumerState<BarangScreen> createState() => _BarangScreenState();
}

class _BarangScreenState extends ConsumerState<BarangScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
            expandedHeight: 120, // Kita kembalikan ke tinggi yang proporsional
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              // Posisi title dikembalikan normal ke bawah lengkungan
              titlePadding: EdgeInsets.only(left: 48, bottom: 16), // Left 48 agar tidak menabrak tombol Back
              title: Text(
                'Master Data Barang', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
              ),
            ),
          ),
          SliverToBoxAdapter(
            // Hapus Transform.translate, cukup gunakan Padding biasa
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16), // Top 24 memberi jarak napas dari lengkungan header
              child: _buildSearchBar(primaryColor),
            ),
          ),
          barangState.when(
            data: (listBarang) {
              final filteredList = listBarang.where((barang) {
                final query = _searchQuery.toLowerCase();
                final namaMatch = barang.namaBarang.toLowerCase().contains(query);
                final kategoriMatch = barang.kategori?.label.toLowerCase().contains(query) ?? false;
                return namaMatch || kategoriMatch;
              }).toList();

              if (listBarang.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(Icons.inventory_2_outlined, 'Belum Ada Data', 'Data barang Anda masih kosong. Silakan tambah barang baru.'),
                );
              }

              if (filteredList.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(Icons.search_off_rounded, 'Tidak Ditemukan', 'Barang dengan kata kunci "$_searchQuery" tidak ada dalam sistem.'),
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
            error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Terjadi kesalahan: $error'))),
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

  Widget _buildSearchBar(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari nama atau kategori...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF1E3A5F).withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, size: 64, color: const Color(0xFF1E3A5F).withAlpha(80)),
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(color: primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(
                barang.namaBarang.isNotEmpty ? barang.namaBarang[0].toUpperCase() : '?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: primaryColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(barang.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(barang.kategori?.label ?? 'Umum', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Stok: ${barang.stock}',
                      style: TextStyle(color: isLowStock ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                InkWell(
                  onTap: () => _showFormBottomSheet(context, barang: barang),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.edit_rounded, color: Colors.blue.shade600, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _confirmDelete(context, ref, barang),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 20),
                  ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Barang', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus data "${barang.namaBarang}"? Tindakan ini tidak dapat dibatalkan.'),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              ref.read(barangControllerProvider.notifier).deleteBarang(barang.idBarang!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

void _showFormBottomSheet(BuildContext context, {BarangModel? barang}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
  BarangKategori? _selectedKategori;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.barang?.namaBarang);
    _stockCtrl = TextEditingController(text: widget.barang?.stock.toString() ?? '0');
    _selectedKategori = widget.barang?.kategori;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newBarang = BarangModel(
      idBarang: widget.barang?.idBarang,
      namaBarang: _namaCtrl.text.trim(),
      kategori: _selectedKategori,
      stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
    );

    try {
      if (widget.barang != null) {
        await ref.read(barangControllerProvider.notifier).updateBarang(newBarang);
      } else {
        await ref.read(barangControllerProvider.notifier).addBarang(newBarang);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar(e.toString());
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String errorMessage) {
    final sanitizedMessage = errorMessage.replaceAll('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sanitizedMessage), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.barang != null;
    final primaryColor = const Color(0xFF1E3A5F);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Text(
              isEdit ? 'Edit Data Barang' : 'Tambah Barang Baru',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _namaCtrl,
              label: 'Nama Barang',
              textCapitalization: TextCapitalization.words,
              validator: (val) => val!.isEmpty ? 'Nama barang wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _stockCtrl,
              label: 'Stok Awal',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(isEdit, primaryColor),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<BarangKategori>(
      value: _selectedKategori,
      decoration: InputDecoration(
        labelText: 'Kategori',
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: BarangKategori.values.map((k) {
        return DropdownMenuItem(value: k, child: Text(k.label));
      }).toList(),
      onChanged: (newValue) {
        setState(() => _selectedKategori = newValue);
      },
    );
  }

  Widget _buildSubmitButton(bool isEdit, Color primaryColor) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: _isSubmitting ? null : _submitForm,
      child: _isSubmitting
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            )
          : Text(
              isEdit ? 'Simpan Perubahan' : 'Simpan Barang',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }
}