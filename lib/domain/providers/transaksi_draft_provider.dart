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
    if (state.idPencatatan == null) return;
    await _repository.addItemToDraft(
      idPencatatan: state.idPencatatan!,
      idBarang: idBarang,
      idMobil: idMobil,
      idToko: idToko,
      qty: qty,
      hargaEstimasi: hargaEstimasi,
    );
    // Refresh list item langsung dari database
    final items = await _repository.getDraftItems(state.idPencatatan!.toInt());
    state = state.copyWith(items: items);
  }

  Future<void> hapusItemDariDraft(int idDetail) async {
    await _repository.removeItemFromDraft(idDetail);
    final items = await _repository.getDraftItems(state.idPencatatan!);
    state = state.copyWith(items: items);
  }
}

final transaksiDraftProvider = StateNotifierProvider.autoDispose<TransaksiDraftNotifier, DraftState>((ref) {
  final repo = ref.watch(transaksiRepositoryProvider);
  final uid = ref.watch(authStateProvider).value!.uid;
  return TransaksiDraftNotifier(repo, uid);
});