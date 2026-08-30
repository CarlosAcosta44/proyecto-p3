import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import '../../datos/local/base_local.dart';
import '../../datos/repositorios/inventario_repositorio.dart';
import '../../dominio/servicios/sincronizacion_servicio.dart';

final dbProvider = FutureProvider<Database>((ref) async {
  return await openLocalDatabase();
});

final inventarioRepoProvider = Provider<InventarioRepositorio?>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => InventarioRepositorio(db),
    loading: () => null,
    error: (_, __) => null,
  );
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);
  return dio;
});

final syncServicioProvider = Provider<SincronizacionServicio?>((ref) {
  final repo = ref.watch(inventarioRepoProvider);
  final dio = ref.watch(dioProvider);
  if (repo == null) return null;
  return SincronizacionServicio(repo, dio);
});
