import 'package:sqflite/sqflite.dart';
import '../../dominio/entidades/item.dart';

class InventarioRepositorio {
  final Database db;

  InventarioRepositorio(this.db);

  Future<List<Item>> obtenerTodos() async {
    final filas = await db.query('item');
    return filas.map((f) => Item.desdeMapa(f)).toList();
  }

  Future<Item?> registrarConteo(String codigo, int cantidad, {String? fotoRuta, String? estado}) async {
    final filas = await db.query('item', where: 'codigo_barras = ?', whereArgs: [codigo]);
    
    if (filas.isEmpty) {
      return null; // Código desconocido
    }

    final itemActual = Item.desdeMapa(filas.first);
    final modificadoEn = DateTime.now().toUtc().toIso8601String();

    final dataToUpdate = {
      'cantidad': cantidad,
      'estado': estado ?? itemActual.estado,
      'sucio': 1,
      'modificado_en': modificadoEn,
    };
    if (fotoRuta != null) {
      dataToUpdate['foto_ruta'] = fotoRuta;
    }

    await db.update(
      'item',
      dataToUpdate,
      where: 'codigo_barras = ?',
      whereArgs: [codigo]
    );

    return itemActual.copiarCon(
      cantidad: cantidad,
      estado: estado ?? itemActual.estado,
      sucio: 1,
      modificadoEn: modificadoEn,
      fotoRuta: fotoRuta ?? itemActual.fotoRuta,
    );
  }

  Future<List<Item>> obtenerSucios() async {
    final filas = await db.query('item', where: 'sucio = ?', whereArgs: [1]);
    return filas.map((f) => Item.desdeMapa(f)).toList();
  }

  Future<void> actualizarTrasSincronizacion(List<dynamic> aplicados, List<Item> remotos) async {
    await db.transaction((txn) async {
      for (final id in aplicados) {
        await txn.update(
          'item',
          {'sucio': 0},
          where: 'id = ? AND sucio = 1',
          whereArgs: [id],
        );
      }
      
      for (final r in remotos) {
        final filas = await txn.query('item', columns: ['id'], where: 'id = ?', whereArgs: [r.id]);
        final data = r.aMapa();
        data['sucio'] = 0; // The remote is clean
        
        if (filas.isNotEmpty) {
          await txn.update('item', data, where: 'id = ?', whereArgs: [r.id]);
        } else {
          await txn.insert('item', data);
        }
      }
    });
  }

  Future<void> guardarItemGanador(Item itemGanador) async {
    final data = itemGanador.aMapa();
    data['sucio'] = 1; 
    data['modificado_en'] = DateTime.now().toUtc().toIso8601String();
    
    await db.update(
      'item',
      data,
      where: 'id = ?',
      whereArgs: [itemGanador.id]
    );
  }
}
