import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_order/data/models/keranjang_item_model.dart';

class KeranjangNotifier extends StateNotifier<List<KeranjangItem>> {
  KeranjangNotifier() : super([]);

  void tambahItem(KeranjangItem item) {
    state = [...state, item];
  }

  void hapusItem(int index) {
    state = [
      ...state.sublist(0, index),
      ...state.sublist(index + 1)
    ];
  }

  void clearKeranjang() {
    state = [];
  }

  double get grandTotal {
    return state.fold(0, (total, item) => total + item.subtotal);
  }
}

final keranjangProvider = StateNotifierProvider<KeranjangNotifier, List<KeranjangItem>>((ref) {
  return KeranjangNotifier();
});