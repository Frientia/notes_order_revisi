import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/toko_model.dart';
import '../../domain/providers/toko_provider.dart';

class TokoScreen extends ConsumerStatefulWidget {
  const TokoScreen({super.key});

  @override
  ConsumerState<TokoScreen> createState() => _TokoScreenState();
}

class _TokoScreenState extends ConsumerState<TokoScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokoState = ref.watch(tokoControllerProvider);
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
                'Master Data Toko', 
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
          tokoState.when(
            data: (listToko) {
              final filteredList = listToko.where((toko) {
                final query = _searchQuery.toLowerCase();
                return toko.namaToko.toLowerCase().contains(query) ||
                    toko.alamat.toLowerCase().contains(query);
              }).toList();

              if (listToko.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(Icons.storefront_outlined, 'Belum Ada Data', 'Data toko Anda masih kosong. Silakan tambah toko baru.'),
                );
              }

              if (filteredList.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(Icons.search_off_rounded, 'Tidak Ditemukan', 'Toko dengan kata kunci "$_searchQuery" tidak ada dalam sistem.'),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _TokoListItem(toko: filteredList[index]),
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
        label: const Text('Tambah Toko', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          hintText: 'Cari nama toko atau alamat...',
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

class _TokoListItem extends ConsumerWidget {
  final TokoModel toko;

  const _TokoListItem({required this.toko});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(color: primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Icon(Icons.storefront_rounded, color: primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(toko.namaToko, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(toko.noTelp, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          toko.alamat, 
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                InkWell(
                  onTap: () => _showFormBottomSheet(context, toko: toko),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.edit_rounded, color: Colors.blue.shade600, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _confirmDelete(context, ref, toko),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, TokoModel toko) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Toko', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus toko "${toko.namaToko}"? Tindakan ini tidak dapat dibatalkan.'),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              ref.read(tokoControllerProvider.notifier).deleteToko(toko.idToko!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

void _showFormBottomSheet(BuildContext context, {TokoModel? toko}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TokoFormSheet(toko: toko),
  );
}

class _TokoFormSheet extends ConsumerStatefulWidget {
  final TokoModel? toko;

  const _TokoFormSheet({this.toko});

  @override
  ConsumerState<_TokoFormSheet> createState() => _TokoFormSheetState();
}

class _TokoFormSheetState extends ConsumerState<_TokoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaTokoCtrl;
  late final TextEditingController _telponCtrl;
  late final TextEditingController _alamatCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _namaTokoCtrl = TextEditingController(text: widget.toko?.namaToko);
    _telponCtrl = TextEditingController(text: widget.toko?.noTelp);
    _alamatCtrl = TextEditingController(text: widget.toko?.alamat);
  }

  @override
  void dispose() {
    _namaTokoCtrl.dispose();
    _telponCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newToko = TokoModel(
      idToko: widget.toko?.idToko,
      namaToko: _namaTokoCtrl.text.trim(),
      noTelp: _telponCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
    );

    try {
      if (widget.toko != null) {
        await ref.read(tokoControllerProvider.notifier).updateToko(newToko);
      } else {
        await ref.read(tokoControllerProvider.notifier).addToko(newToko);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar(e.toString());
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String errorMessage) {
    if (!mounted) return;
    final sanitizedMessage = errorMessage.replaceAll('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sanitizedMessage), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.toko != null;
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
              isEdit ? 'Edit Data Toko' : 'Tambah Toko Baru',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _namaTokoCtrl,
              label: 'Nama Toko',
              textCapitalization: TextCapitalization.words,
              validator: (val) => val!.isEmpty ? 'Nama toko wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _telponCtrl,
              label: 'Nomor Telepon',
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _alamatCtrl,
              label: 'Alamat Lengkap',
              maxLines: 3,
              validator: (val) => val!.isEmpty ? 'Alamat wajib diisi' : null,
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  String? _validatePhone(String? val) {
    if (val == null || val.isEmpty) return 'Nomor telepon wajib diisi';
    if (!RegExp(r'^[0-9]+$').hasMatch(val)) return 'Hanya boleh berisi angka';
    return null;
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
              isEdit ? 'Simpan Perubahan' : 'Simpan Toko',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }
}