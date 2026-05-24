import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mobil_model.dart';

final mobilRepositoryProvider = Provider<MobilRepository>((ref) {
  return MobilRepository(Supabase.instance.client);
});

class MobilRepository {
  final SupabaseClient _supabase;

  MobilRepository(this._supabase);

  Future<List<MobilModel>> getMobil() async {
    final response = await _supabase
        .from('mobil')
        .select()
        .order('no_plat', ascending: true);
    
    return response.map((e) => MobilModel.fromJson(e)).toList();
  }

  Future<MobilModel> addMobil(MobilModel mobil) async {
    // Mengecek apakah no_plat sudah ada agar tidak error unique constraint
    final cekPlat = await _supabase.from('mobil').select().eq('no_plat', mobil.noPlat);
    if (cekPlat.isNotEmpty) throw Exception('Nomor Plat sudah terdaftar!');

    final response = await _supabase
        .from('mobil')
        .insert(mobil.toJson())
        .select()
        .single();
    return MobilModel.fromJson(response);
  }

  Future<void> updateMobil(MobilModel mobil) async {
    await _supabase
        .from('mobil')
        .update(mobil.toJson())
        .eq('id_mobil', mobil.idMobil!);
  }

  Future<void> deleteMobil(String idMobil) async {
    await _supabase
        .from('mobil')
        .delete()
        .eq('id_mobil', idMobil);
  }
}