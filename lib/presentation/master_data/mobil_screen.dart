import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mobil_model.dart';
import '../../domain/providers/mobil_provider.dart';

class MobilScreen extends ConsumerStatefulWidget {
  const MobilScreen({super.key});

  @override
  ConsumerState<MobilScreen> createState() => _MobilScreenState();
}

class _MobilScreenState extends ConsumerState<MobilScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobilState = ref.watch(mobilControllerProvider);
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
              title: Text(
                'Master Data Mobil', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: _buildSearchBar(primaryColor),
            ),
          ),
          mobilState.when(
            data: (listMobil) {
              final filteredList = listMobil.where((mobil) {
                final query = _searchQuery.toLowerCase();
                final platMatch = mobil.noPlat.toLowerCase().contains(query);
                final kategoriMatch = mobil.kategori?.label.toLowerCase().contains(query) ?? false;
                return platMatch || kategoriMatch;
              }).toList();

              if (listMobil.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(Icons.directions_car_filled_outlined, 'Belum Ada Data', 'Data mobil Anda masih kosong. Silakan tambah mobil baru.'),
                );
              }

              if (filteredList.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(Icons.search_off_rounded, 'Tidak Ditemukan', 'Mobil dengan kata kunci "$_searchQuery" tidak ada dalam sistem.'),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _MobilListItem(mobil: filteredList[index]),
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
        label: const Text('Tambah Mobil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          hintText: 'Cari plat mobil atau kategori...',
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

class _MobilListItem extends ConsumerWidget {
  final MobilModel mobil;

  const _MobilListItem({required this.mobil});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = const Color(0xFF1E3A5F);

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
              child: Icon(Icons.directions_car, color: primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mobil.noPlat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(mobil.kategori?.label ?? 'Tanpa Kategori', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'Tahun: ${mobil.tahun ?? '-'}',
                      style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                InkWell(
                  onTap: () => _showFormBottomSheet(context, mobil: mobil),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.edit_rounded, color: Colors.blue.shade600, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _confirmDelete(context, ref, mobil),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, MobilModel mobil) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Mobil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus mobil dengan plat "${mobil.noPlat}"? Tindakan ini tidak dapat dibatalkan.'),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              ref.read(mobilControllerProvider.notifier).deleteMobil(mobil.idMobil!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

void _showFormBottomSheet(BuildContext context, {MobilModel? mobil}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MobilFormSheet(mobil: mobil),
  );
}

class _MobilFormSheet extends ConsumerStatefulWidget {
  final MobilModel? mobil;

  const _MobilFormSheet({this.mobil});

  @override
  ConsumerState<_MobilFormSheet> createState() => _MobilFormSheetState();
}

class _MobilFormSheetState extends ConsumerState<_MobilFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _platCtrl;
  late final TextEditingController _tahunCtrl;
  MobilKategori? _selectedKategori;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _platCtrl = TextEditingController(text: widget.mobil?.noPlat);
    _tahunCtrl = TextEditingController(text: widget.mobil?.tahun?.toString() ?? '');
    _selectedKategori = widget.mobil?.kategori;
  }

  @override
  void dispose() {
    _platCtrl.dispose();
    _tahunCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newMobil = MobilModel(
      idMobil: widget.mobil?.idMobil ?? '',
      noPlat: _platCtrl.text.trim().toUpperCase(),
      kategori: _selectedKategori,
      tahun: int.tryParse(_tahunCtrl.text.trim()),
    );

    try {
      if (widget.mobil != null) {
        await ref.read(mobilControllerProvider.notifier).updateMobil(newMobil);
      } else {
        await ref.read(mobilControllerProvider.notifier).addMobil(newMobil);
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
    final isEdit = widget.mobil != null;
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
              isEdit ? 'Edit Data Mobil' : 'Tambah Mobil Baru',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _platCtrl,
              label: 'No. Plat (Contoh: B 1234 CD)',
              textCapitalization: TextCapitalization.characters,
              validator: (val) => val!.isEmpty ? 'No. Plat wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _tahunCtrl,
              label: 'Tahun Kendaraan',
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
    return DropdownButtonFormField<MobilKategori>(
      value: _selectedKategori,
      decoration: InputDecoration(
        labelText: 'Kategori',
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: MobilKategori.values.map((kategori) {
        return DropdownMenuItem(value: kategori, child: Text(kategori.label));
      }).toList(),
      onChanged: (newValue) {
        setState(() => _selectedKategori = newValue);
      },
      validator: (val) => val == null ? 'Kategori wajib dipilih' : null,
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
              isEdit ? 'Simpan Perubahan' : 'Simpan Mobil',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }
}