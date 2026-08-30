import 'package:dio/dio.dart';
import '../../datos/repositorios/inventario_repositorio.dart';
import '../entidades/item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SincronizacionServicio {
  final InventarioRepositorio repositorio;
  final Dio dio;

  SincronizacionServicio(this.repositorio, this.dio);

  Future<void> sincronizar() async {
    final sucios = await repositorio.obtenerSucios();
    final prefs = await SharedPreferences.getInstance();
    final ultimaSync = prefs.getString('ultimaSync') ?? '1970-01-01T00:00:00Z';

    final payload = {
      'ultimaSync': ultimaSync,
      'cambiosLocales': sucios.map((s) => {
        'id': s.id,
        'codigo_barras': s.codigoBarras,
        'nombre': s.nombre,
        'cantidad': s.cantidad,
        'estado': s.estado,
        'version': s.version,
        'fotoBase64': s.fotoRuta,
        'modificadoEn': s.modificadoEn,
      }).toList(),
    };

    try {
      // Ajustar URL según el entorno (para dispositivo físico usaremos adb reverse con localhost)
      final respuesta = await dio.post('http://192.168.11.10:3000/api/sync', data: payload);
      final data = respuesta.data;
      
      final aplicados = List<String>.from(data['aplicados'] ?? []);
      final remotosData = List<Map<String, dynamic>>.from(data['cambiosRemotos'] ?? []);
      final remotos = remotosData.map((e) => Item.desdeMapa(e)).toList();
      
      final conflictos = List<Map<String, dynamic>>.from(data['conflictos'] ?? []);
      
      await repositorio.actualizarTrasSincronizacion(aplicados, remotos);
      
      if (data['servidorEn'] != null && conflictos.isEmpty) {
        await prefs.setString('ultimaSync', data['servidorEn']);
      }
      
      if (conflictos.isNotEmpty) {
        throw ConflictosException(conflictos);
      }
    } catch (e) {
      rethrow;
    }
  }
}

class ConflictosException implements Exception {
  final List<Map<String, dynamic>> conflictos;
  ConflictosException(this.conflictos);
}
