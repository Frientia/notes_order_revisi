import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/dashboard_boss_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(Supabase.instance.client);
});

// FutureProvider akan otomatis memanggil fungsi getDashboardData()
final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.getDashboardData();
});
