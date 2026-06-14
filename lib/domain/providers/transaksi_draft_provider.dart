import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transaksi_repository.dart';
import 'auth_provider.dart';

class DraftState {
  final int? idPencatatan;
  final List<Map<String, dynamic>> items;
  final bool isLoading;

  DraftState({this.idPencatatan, this.items = const [], this.isLoading = false});

  DraftState copyWith({int? idPencatatan, List<Map<String, dynamic>>? items, bool? isLoading}) {
    return DraftState(
      idPencatatan: idPencatatan ?? this.idPencatatan,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TransaksiDraftNotifier extends StateNotifier<DraftState> {
  final TransaksiRepository _repository;
  final String _firebaseUid;

  TransaksiDraftNotifier(this._repository, this._firebaseUid) : super(DraftState(isLoading: true)) {
    initDraft();
  }

  Future<void> initDraft() async {
    state = state.copyWith(isLoading: true);
    try {
      final id = await _repository.getOrCreateActiveDraft(_firebaseUid);
      final items = await _repository.getDraftItems(id);
      state = DraftState(idPencatatan: id, items: items, isLoading: false);
    } catch (e) {
      // === PERBAIKAN DI SINI: Jangan diam saja, print errornya ke console! ===
      print("🚨🚨🚨 GAGAL MEMBUAT DRAFT DI SUPABASE 🚨🚨🚨");
      print(e.toString());
      print("🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨");
      
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> tambahItemKeDraft({
    required int idBarang,
    required int idMobil,
    required int idToko,
    required int qty,
    double hargaEstimasi = 0,
  }) async {
    if (state.idPencatatan == null) {
      // Jika draft belum terbuat, lempar error
      throw Exception('ID Draft belum siap. Coba kembali ke menu utama lalu buka lagi.');
    }
    
    try {
      await _repository.addItemToDraft(
        idPencatatan: state.idPencatatan!,
        idBarang: idBarang,
        idMobil: idMobil,
        idToko: idToko,
        qty: qty,
        hargaEstimasi: hargaEstimasi,
      );
      // Refresh list item langsung dari database
      final items = await _repository.getDraftItems(state.idPencatatan!);
      state = state.copyWith(items: items);
    } catch (e) {
      // Melempar error ke UI agar muncul di layar
      throw Exception(e.toString()); 
    }
  }

  Future<void> hapusItemDariDraft(int idDetail) async {
    await _repository.removeItemFromDraft(idDetail);
    final items = await _repository.getDraftItems(state.idPencatatan!);
    state = state.copyWith(items: items);
  }

  // === FUNGSI BARU: EDIT QTY DI DRAFT ===
  Future<void> updateQtyItemDraft(int idDetail, int newQty) async {
    // 1. Optimistic Update (Ubah UI seketika tanpa nunggu loading DB)
    state = state.copyWith(
      items: state.items.map((item) {
        if (item['id_detail_pencatatan'] == idDetail) {
          return {...item, 'qty': newQty}; 
        }
        return item;
      }).toList(),
    );

    try {
      await _repository.updateQtyItemDraft(idDetail, newQty);
    } catch (e) {
      // 3. Rollback jika koneksi internet terputus/gagal
      final items = await _repository.getDraftItems(state.idPencatatan!);
      state = state.copyWith(items: items);
      throw Exception('Gagal mengubah Qty di database');
    }
  }
}

final transaksiDraftProvider = StateNotifierProvider.autoDispose<TransaksiDraftNotifier, DraftState>((ref) {
  final repo = ref.watch(transaksiRepositoryProvider);
  final uid = ref.watch(authStateProvider).value!.uid;
  return TransaksiDraftNotifier(repo, uid);
});