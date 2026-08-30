import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dominio/entidades/item.dart';
import 'proveedores.dart';
import '../../dominio/servicios/sincronizacion_servicio.dart';

class InventarioEstado {
  final List<Item> items;
  final bool cargando;
  final String? error;

  InventarioEstado({this.items = const [], this.cargando = true, this.error});

  InventarioEstado copiarCon({List<Item>? items, bool? cargando, String? error}) {
    return InventarioEstado(
      items: items ?? this.items,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

class InventarioNotifier extends StateNotifier<InventarioEstado> {
  final Ref ref;

  InventarioNotifier(this.ref) : super(InventarioEstado()) {
    cargarInventario();
  }

  Future<void> cargarInventario() async {
    state = state.copiarCon(cargando: true, error: null);
    try {
      final repo = ref.read(inventarioRepoProvider);
      if (repo == null) return;
      final items = await repo.obtenerTodos();
      state = state.copiarCon(items: items, cargando: false);
    } catch (e) {
      state = state.copiarCon(cargando: false, error: e.toString());
    }
  }

  Future<bool> sincronizar() async {
    state = state.copiarCon(cargando: true, error: null);
    try {
      final servicio = ref.read(syncServicioProvider);
      if (servicio == null) {
        state = state.copiarCon(cargando: false, error: 'Servicio no disponible');
        return false;
      }
      await servicio.sincronizar();
      await cargarInventario();
      return true;
    } on ConflictosException catch (e) {
      state = state.copiarCon(cargando: false, error: 'CONFLICTO');
      throw e;
    } catch (e) {
      state = state.copiarCon(cargando: false, error: e.toString());
      return false;
    }
  }

  Future<void> registrarConteo(String codigo, int cantidad, {String? fotoRuta, String? estado}) async {
    try {
      final repo = ref.read(inventarioRepoProvider);
      if (repo == null) return;
      await repo.registrarConteo(codigo, cantidad, fotoRuta: fotoRuta, estado: estado);
      await cargarInventario();
    } catch (e) {
      state = state.copiarCon(error: e.toString());
    }
  }
  
  Future<void> resolverConflicto(Item ganador) async {
    try {
      final repo = ref.read(inventarioRepoProvider);
      if (repo == null) return;
      await repo.guardarItemGanador(ganador);
      await cargarInventario();
    } catch (e) {
      state = state.copiarCon(error: e.toString());
    }
  }
}

final inventarioProvider = StateNotifierProvider<InventarioNotifier, InventarioEstado>((ref) {
  return InventarioNotifier(ref);
});
