import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
Future<Database> openLocalDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'inventario.db');
  
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE item (
          id TEXT PRIMARY KEY,
          codigo_barras TEXT NOT NULL,
          nombre TEXT NOT NULL,
          cantidad INTEGER NOT NULL,
          estado TEXT NOT NULL,
          version INTEGER NOT NULL,
          sucio INTEGER NOT NULL DEFAULT 0, -- 1 = pendiente de subir
          foto_ruta TEXT,
          modificado_en TEXT
        );
      ''');
      await db.execute('CREATE INDEX idx_item_codigo ON item(codigo_barras)');
      await db.execute('CREATE INDEX idx_item_sucio ON item(sucio)');
    },
  );
}
